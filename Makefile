SHELL=fish

.PHONY: check format

check:
	nix flake check path:.

format:
	alejandra **/*.nix
