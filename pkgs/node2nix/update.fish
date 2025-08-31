#!/usr/bin/env fish

# node2nix -i node-packages.json

# Reduce size and build errors by ignoring optional dependencies
node2nix --strip-optional-dependencies -i node-packages.json
