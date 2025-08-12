class LicenseCheck:
    def __init__(self) -> None:
        self.airgapped_license_data = None

    def _verify(self, license_str: str) -> bool:
        return True

    def is_premium(self) -> bool:
        return True

    def is_over_limit(self, total_users: int) -> bool:
        return False

    def is_team_count_over_limit(self, team_count: int) -> bool:
        return False

    def verify_license_without_api_request(self, public_key, license_key):
        return True
