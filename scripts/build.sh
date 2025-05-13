#!/bin/sh

set -e

scripts/build-single-file.sh .darklua-bundle.json build/tag-effect.luau
scripts/build-single-file.sh .darklua-bundle-dev.json build/debug/tag-effect.luau
scripts/build-roblox-model.sh .darklua.json build/tag-effect.rbxm
scripts/build-roblox-model.sh .darklua-dev.json build/debug/tag-effect.rbxm
