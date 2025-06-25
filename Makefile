SHELL=fish
MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MAKEFILE_DIR := $(dir $(MAKEFILE_PATH))

.PHONY: check format

check:
	nix flake check path:${MAKEFILE_DIR}

lint:
	nixpkgs-lint .

format:
	alejandra **/*.nix
