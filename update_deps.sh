#!/bin/sh

set -xe

#rm -rf YAVSRG
#git clone --depth 1 https://github.com/YAVSRG/YAVSRG --branch interlude-v0.7.28.1 --recursive --shallow-submodules
pushd YAVSRG/
nix shell nixpkgs#dotnet-sdk_9 --command dotnet restore --runtime linux-arm64 --packages out
nix shell nixpkgs#nuget-to-json nixpkgs#dotnet-sdk_9 --command nuget-to-json out > deps.json
jq 'del(.[] | select(.pname == "Microsoft.NET.ILLink.Tasks" and .version == "9.0.10"))' deps.json > deps.cleaned.json
mv deps.cleaned.json deps.json
jq 'del(.[] | select(.pname == "Microsoft.AspNetCore.App.Runtime.linux-arm64" and .version == "9.0.10"))' deps.json > deps.cleaned.json
mv deps.cleaned.json deps.json
jq 'del(.[] | select(.pname == "Microsoft.NETCore.App.Runtime.linux-arm64" and .version == "9.0.10"))' deps.json > deps.cleaned.json
mv deps.cleaned.json deps.json

popd
mv YAVSRG/deps.json .

