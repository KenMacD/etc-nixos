#!/usr/bin/env bash

FAILED_UPDATES=()

echo "Fetching package list..."
PACKAGES=$(nix flake show --json | jq -r ".packages.[] | keys[]")

for pkg in $PACKAGES; do
    echo "Updating $pkg..."
    if nix-update "$pkg" --flake; then
        echo "✓ Successfully updated $pkg"
    else
        echo "✗ Failed to update $pkg"
        FAILED_UPDATES+=("$pkg")
    fi
    echo "---"
done

if [ ${#FAILED_UPDATES[@]} -gt 0 ]; then
    echo "Failed to update: ${FAILED_UPDATES[*]}"
else
    echo "All packages updated successfully!"
fi
