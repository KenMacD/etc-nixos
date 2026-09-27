import re
from typing import Final

from litellm.secret_managers.main import get_secret_str
from litellm.types.llms.openai import AllMessageValues, ChatCompletionToolParam

from ...openai.chat.gpt_transformation import OpenAIGPTConfig

ZAI_API_BASE: Final = "https://api.z.ai/api/paas/v4"
_GLM_VERSION_PATTERN: Final = re.compile(r"glm-(\d+)(?:\.(\d+))?")


def _glm_version(model: str) -> tuple[int, int] | None:
    match = _GLM_VERSION_PATTERN.search(model.lower())
    if match is None:
        return None
    return (int(match.group(1)), int(match.group(2) or 0))


def _supports_native_reasoning_effort(model: str) -> bool:
    """Z.AI only accepts reasoning_effort natively on GLM-5.2 and above."""
    version = _glm_version(model)
    return version is not None and version >= (5, 2)


class ZAIChatConfig(OpenAIGPTConfig):
    @property
    def custom_llm_provider(self) -> str | None:
        return "zai"

    def _get_openai_compatible_provider_info(
        self, api_base: str | None, api_key: str | None
    ) -> tuple[str | None, str | None]:
        api_base = api_base or get_secret_str("ZAI_API_BASE") or ZAI_API_BASE
        dynamic_api_key: Final = api_key or get_secret_str("ZAI_API_KEY")
        return api_base, dynamic_api_key

    def remove_cache_control_flag_from_messages_and_tools(
        self,
        model: str,
        messages: list[AllMessageValues],
        tools: list[ChatCompletionToolParam] | None = None,
    ) -> tuple[list[AllMessageValues], list[ChatCompletionToolParam] | None]:
        """
        Override to preserve cache_control for GLM/ZAI.
        GLM supports cache_control - don't strip it.
        """
        # GLM/ZAI supports cache_control, so return messages and tools unchanged
        return messages, tools

    def _is_reasoning_model(self, model: str) -> bool:
        """GLM-4.5 and newer support thinking; ids outside that shape fall back to the model map."""
        version = _glm_version(model)
        if version is not None:
            return version >= (4, 5)
        import litellm

        try:
            return bool(litellm.supports_reasoning(model=model, custom_llm_provider=self.custom_llm_provider))
        except Exception:
            return False

    def get_supported_openai_params(self, model: str) -> list:
        base_params: Final = [
            "max_tokens",
            "stream",
            "stream_options",
            "temperature",
            "top_p",
            "stop",
            "tools",
            "tool_choice",
        ]

        if self._is_reasoning_model(model):
            base_params.extend(["thinking", "reasoning_effort"])

        return base_params

    def map_openai_params(
        self,
        non_default_params: dict,
        optional_params: dict,
        model: str,
        drop_params: bool,
    ) -> dict:
        """
        GLM-5.2 and above accept reasoning_effort natively (5.2 additionally accepts
        "none", which skips thinking; 5.3/5.3-flash only accept "max", "high" and
        "low"), so other efforts are forwarded as-is. "none" is out-of-enum on
        5.3/5.3-flash and pre-5.2 models only expose the `thinking` toggle, so "none"
        is always translated to `thinking: {"type": "disabled"}` — the one
        skip-thinking switch every GLM-4.5+ model honors. "default" leaves the
        provider default, and on pre-5.2 models any other effort enables thinking.
        """
        native_effort: Final = _supports_native_reasoning_effort(model)
        mapped_params: Final = super().map_openai_params(
            non_default_params={
                key: value for key, value in non_default_params.items() if key != "reasoning_effort" or native_effort
            },
            optional_params=optional_params,
            model=model,
            drop_params=drop_params,
        )
        effort = non_default_params.get("reasoning_effort")
        if not isinstance(effort, str) or effort == "default":
            return mapped_params
        if native_effort and effort != "none":
            return mapped_params
        mapped_params.pop("reasoning_effort", None)
        extra_body: Final = mapped_params.setdefault("extra_body", {})
        already_set: Final = "thinking" in optional_params or "thinking" in extra_body
        if not already_set:
            extra_body["thinking"] = {"type": "disabled" if effort == "none" else "enabled"}
        return mapped_params
