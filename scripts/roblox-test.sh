#!/bin/sh

set -e

DARKLUA_CONFIG=".darklua-tests.json"

if [ ! -d node_modules ]; then
    rm -rf temp
    yarn install
fi

if [ -d "temp" ]; then
    ls -d temp/* | grep -v node_modules | xargs rm -rf
fi

rojo sourcemap test-place.project.json -o sourcemap.json

darklua process --config $DARKLUA_CONFIG jest.config.luau temp/jest.config.luau
darklua process --config $DARKLUA_CONFIG scripts/roblox-test.server.luau temp/scripts/roblox-test.server.luau
darklua process --config $DARKLUA_CONFIG node_modules temp/node_modules
darklua process --config $DARKLUA_CONFIG src temp/src

cp test-place.project.json temp/

rojo build temp/test-place.project.json -o temp/test-place.rbxl

run-in-roblox --place temp/test-place.rbxl --script temp/scripts/roblox-test.server.luau
