{
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        version = "0.7.28.1"; # I really fucking wish input values could be thunks
        pkgs = import nixpkgs { inherit system; };
        exe = "Interlude";
        game = pkgs.fetchFromGitHub {
          owner = "YAVSRG";
          repo = "YAVSRG";
          rev = "interlude-v0.7.28.1";
          sha256 = "sha256-0Qbnywbq4cs/WPhvCou31FFKdqjRhZ4Aww06D1h5Nx4=";
          fetchSubmodules = true;
        };
      in
      {
        packages = rec {
          yavsrg = pkgs.buildDotnetModule {
            pname = "yavsrg";
            version = version;

            src = game;

            projectFile = "interlude/src/Interlude.fsproj";
            nugetDeps = ./deps.json;

            dotnet-sdk = pkgs.dotnetCorePackages.sdk_9_0;
            dotnet-runtime = pkgs.dotnetCorePackages.runtime_9_0;

            dotnetFlags = [
              "-p:RuntimeIdentifiers="
            ];

            runtimeDeps = with pkgs; [
              libbass
              libbass_fx
              glfw
              libGL
            ] ++ pkgs.lib.optionals !pkgs.stdenv.isDarwin [
              alsa-lib
            ];

            patches = [
              ./add_environ.patch
              ./remove_logger.patch
            ];

            postInstall = ''
              ln -s ${pkgs.libbass}/lib/libbass.so $out/lib/yavsrg/libbass.so
              ln -s ${pkgs.libbass_fx}/lib/libbass_fx.so $out/lib/yavsrg/libbass_fx.so
            '';

            fixupPhase = ''
              runHook preFixup

              cat > "$out/lib/${exe}-ensure-data" <<'EOF'
              #!/usr/bin/env bash
              set -euo pipefail
              conf_dir="$HOME/.local/share/yavsrg"
              conf_file="$conf_dir/config.json"
              mkdir -p "$conf_dir"
              if [ ! -e "$conf_file" ]; then
                printf '{ "WorkingDirectory": "%s" }\n' "$conf_dir" > "$conf_file"
              fi
              EOF
              chmod +x "$out/lib/${exe}-ensure-data"

              wrapProgram "$out/bin/${exe}" \
                --run "$out/lib/${exe}-ensure-data" \
                --run 'export YAVSRG_CONFIG_FILE="$HOME/.local/share/yavsrg/"' \
                --prefix LD_LIBRARY_PATH : "$out/lib/yavsrg"

              runHook postFixup
            '';

            meta = {
              description = "The most based keyboard rhythm game";
              homepage = "https://www.yavsrg.net/";
              license = pkgs.lib.licenses.mit;
              mainProgram = exe;
            };
          };

          default = yavsrg;
        };
      }
    );
}
