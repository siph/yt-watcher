{
  description = "Youtube auto-downloader";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # `0.88.1`
    nixpkgs-nushell.url = "github:NixOS/nixpkgs/baa02207279115f5457c18fef3fc3513f58fa8d2";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nupm = {
      url = "github:siph/nupm/flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix.url = "github:numtide/treefmt-nix";
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
      }: let
        inherit (nixpkgs-nushell.legacyPackages.${system}) nushell;
        treefmtWrapper = config.treefmt.build.wrapper;
        buildInputs = with pkgs; [nushell yt-dlp];
        nupm-test = nupm.packages.${system}.nupm-test;
      in {
        packages = with pkgs; rec {
          yt-watcher = stdenvNoCC.mkDerivation rec {
            nativeBuildInputs = [makeBinaryWrapper];
            inherit buildInputs;
            name = "yt-watcher";
            src = ./.;

            # I don't know if there is any meaningful difference between
            # ```shell
            # nu \
            # --no-config-file \
            # --commands 'use ./yt-watcher ; yt-watcher'
            # ```
            #
            # and
            #
            # ```shell
            # nu ./yt-watcher/mod.nu
            # ```
            installPhase = ''
              mkdir -p $out/bin
              mkdir -p $out/share/${name}
              mv ./* $out/share/${name}
              makeWrapper ${nushell}/bin/nu $out/bin/${name} \
                --add-flags $out/share/${name}/${name}/mod.nu
            '';
          };
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
            buildInputs = buildInputs ++ [treefmtWrapper wiremock];
          };
        };
      };
    };
}
