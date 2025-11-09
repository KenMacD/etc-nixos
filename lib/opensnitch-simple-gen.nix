# Borrowed from https://github.com/prettymuchbryce/dotfiles/blob/8f7350881eabd6e7e02a277a40a145922400e4a4/modules/system/opensnitch/simple-gen.nix
# Placed in opensnitch namespace
#
# OpenSnitch Simple Rule Generator
#
#
# This module provides utilities to generate verbose OpenSnitch rules from a simplified schema.
# Instead of writing 20+ lines of boilerplate per rule, you can define rules concisely.
#
# Example usage:
#   mkSimpleRule {
#     name = "Allow Syncthing TCP sync (LAN)";
#     process = "/nix/store/.../bin/syncthing";
#     port = 22000;
#     protocol = "tcp";
#     network = "LAN";
#   }
#
# This generates a complete OpenSnitch rule with:
# - Rule key: "100-allow-syncthing-tcp-sync-lan"
# - All required boilerplate (enabled=true, precedence=true, action="allow", duration="always")
# - Proper operator structure (single condition vs. list)
# - Correct field types (simple, regexp, network)
#
# Available fields: name (required), process, parentProcess, cmdLine, port, host, ip, network, protocol
{lib, ...}: let
  # Convert rule name to hyphenated key format
  # "Allow Syncthing TCP sync (LAN)" -> "allow-syncthing-tcp-sync-lan"
  nameToKey = name: let
    # List of characters to replace with hyphens
    fromChars = [
      " "
      "("
      ")"
      "["
      "]"
      "."
      ","
      ":"
      ";"
      "&"
      "|"
      "="
      "+"
      "*"
      "?"
      "!"
      "@"
      "#"
      "$"
      "%"
      "^"
      "~"
      "`"
      "'"
      "\""
      "\\"
      "/"
      "<"
      ">"
    ];
    toChars = map (_: "-") fromChars;

    # Convert to lowercase and replace non-alphanumeric chars with hyphens
    normalized = lib.toLower (builtins.replaceStrings fromChars toChars name);
    # Remove multiple consecutive hyphens and trim
    cleaned = lib.concatStringsSep "-" (lib.filter (s: s != "") (lib.splitString "-" normalized));
  in
    cleaned;

  # Generate OpenSnitch rule from simplified schema
  mkSimpleRule = ruleSpec: let
    # Generate the rule key
    ruleKey = "100-${nameToKey ruleSpec.name}";

    # Build the list of conditions based on provided fields
    conditions = lib.flatten [
      # Process path condition
      (lib.optional (ruleSpec.process or null != null) {
        type = "simple";
        sensitive = false;
        operand = "process.path";
        data = ruleSpec.process;
      })

      # Parent process path condition
      (lib.optional (ruleSpec.parentProcess or null != null) {
        type = "simple";
        sensitive = false;
        operand = "process.parent.path";
        data = ruleSpec.parentProcess;
      })

      # Command line condition (regexp type to match process.command)
      (lib.optional (ruleSpec.cmdLine or null != null) {
        type = "regexp";
        sensitive = false;
        operand = "process.command";
        data = ruleSpec.cmdLine;
      })

      # Destination port condition
      (lib.optional (ruleSpec.port or null != null) {
        type = "simple";
        sensitive = false;
        operand = "dest.port";
        data = toString ruleSpec.port;
      })

      # Destination host condition
      (lib.optional (ruleSpec.host or null != null) {
        type = "regexp";
        sensitive = false;
        operand = "dest.host";
        data = ruleSpec.host;
      })

      # Destination IP condition
      (lib.optional (ruleSpec.ip or null != null) {
        type = "regexp";
        sensitive = false;
        operand = "dest.ip";
        data = ruleSpec.ip;
      })

      # Destination network condition
      (lib.optional (ruleSpec.network or null != null) {
        type = "network";
        sensitive = false;
        operand = "dest.network";
        data = ruleSpec.network;
      })

      # Protocol condition
      (lib.optional (ruleSpec.protocol or null != null) {
        type = "simple";
        sensitive = false;
        operand = "protocol";
        data = ruleSpec.protocol;
      })
    ];

    # Generate the operator structure
    operator =
      if (lib.length conditions) == 1
      then
        # Single condition - use the condition directly as operator
        lib.head conditions
      else
        # Multiple conditions - wrap in list
        {
          type = "list";
          operand = "list";
          list = conditions;
        };

    # Generate the complete rule
    rule = {
      name = ruleSpec.name;
      enabled = true;
      precedence = true;
      action = "allow";
      duration = "always";
      inherit operator;
    };
  in {
    ${ruleKey} = rule;
  };

  # Helper to convert multiple rules
  mkSimpleRules = ruleSpecs: lib.mkMerge (map mkSimpleRule ruleSpecs);
in {
  opensnitch = {inherit mkSimpleRule mkSimpleRules nameToKey;};
}
