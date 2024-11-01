{
  description = "Youtube auto-downloader";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # `0.99.1`
    nixpkgs-nushell.url = "github:NixOS/nixpkgs/d3503200cd28f0ecba42a9a4f82988f469932320";
    flake-parts.url = "github:hercules-ci/flake-parts";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix.url = "github:numtide/treefmt-nix";
    nupm = {
      url = "github:nushell/nupm";
      flake = false;
    };
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    nixpkgs-nushell,
    nupm,
    pre-commit-hooks,
    treefmt-nix,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      imports = [
        treefmt-nix.flakeModule
      ];

      perSystem = {
        config,
        lib,
        pkgs,
        self',
        system,
        ...
      }:
        with pkgs; let
          inherit (nixpkgs-nushell.legacyPackages.${system}) nushell;

          treefmtWrapper = config.treefmt.build.wrapper;

          nupm-test = writeShellApplication {
            runtimeInputs = [nupm nushell];
            name = "nupm-test";
            text = ''
              nu --no-config-file \
                --commands '
                  use ${nupm}/nupm

                  nupm test
                '
            '';
          };
        in {
          packages = with pkgs; rec {
            yt-watcher = stdenvNoCC.mkDerivation (finalAttrs: {
              name = "yt-watcher";
              nativeBuildInputs = [makeBinaryWrapper];
              src = ./.;
              installPhase = ''
                mkdir -p $out/bin
                mkdir -p $out/share/${finalAttrs.name}
                mv ./* $out/share/${finalAttrs.name}
                makeWrapper ${nushell}/bin/nu $out/bin/${finalAttrs.name} \
                  --add-flags $out/share/${finalAttrs.name}/${finalAttrs.name}/mod.nu \
                  --prefix PATH : ${lib.makeBinPath [yt-dlp]}
              '';
            });

            default = yt-watcher;
          };

          checks = {
            pre-commit-check = pre-commit-hooks.lib.${system}.run {
              src = ./.;
              hooks.treefmt.enable = true;
              settings.treefmt.package = treefmtWrapper;
            };

            nushell-tests = with pkgs;
              stdenv.mkDerivation {
                inherit system;
                name = "nushell tests";
                src = ./.;
                nativeBuildInputs = [nushell nupm-test];
                buildInputs = [wiremock];
                buildPhase = ''
                  ${wiremock}/bin/wiremock \
                    --disable-banner \
                    --verbose \
                    --root-dir ./tests &

                  sleep 2

                  nupm-test
                '';
                installPhase = ''
                  touch $out
                '';
              };
          };

          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              alejandra.enable = true;
              # nufmt.enable = true;
            };
          };

          devShells = with pkgs; {
            default = mkShell {
              inherit (self'.checks.pre-commit-check) shellHook;
              buildInputs = [nupm-test treefmtWrapper wiremock yt-dlp];
            };
          };
        };
    };
}
