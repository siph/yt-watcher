{
  description = "Youtube auto-downloader";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        buildInputs = with pkgs; [
          nushell
          yt-dlp
        ];
      in with pkgs; rec {
        packages = {
          yt-watcher = stdenv.mkDerivation rec {
            nativeBuildInputs = [ makeWrapper ];
            inherit buildInputs;
            name = "yt-watcher";
            src = ./.;
            installPhase = ''
              mkdir -p $out/bin
              mkdir -p $out/nu
              cp ./${name}.nu $out/nu
              makeWrapper ${nushell}/bin/nu $out/bin/${name} \
                --add-flags "$out/nu/${name}.nu"
            '';
          };
          default = packages.yt-watcher;
        };
        apps = {
          yt-watcher = flake-utils.lib.mkApp { drv = packages.yt-watcher; };
          default = apps.yt-watcher;
        };
        nixosModules = {
          default = { pkgs, lib, config, ... }:
          with lib;
          let
            cfg = config.services.yt-watcher;
          in {
            options.services.yt-watcher = {
              enable = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Run yt-watcher as service.
                '';
              };
            };
            config = mkIf cfg.enable {
              systemd.user = {
                services = {
                  yt-watcher = {
                    Service = {
                      ExecStart = "${(self.packages.${system}.default)}/bin/yt-watcher ~/.config/yt-watcher";
                      Restart = "on-failure";
                      OOMPolicy = "kill";
                    };
                    Unit = {
                      Description = "Youtube auto-downloader";
                      Documentation = "https://www.github.com/siph/yt-watcher";
                    };
                  };
                };
              };
            };
          };
        };
        devShells = {
          default = mkShell {
            inherit buildInputs;
          };
        };
      });
}
