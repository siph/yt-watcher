# yt-watcher

This is an application to automatically download recent Youtube channel
video uploads.


## Configuration

`config.yaml` can be found in `XDG_HOME`. For linux this is typically
`~/.config/yt-watcher`. A default configuration is generated on first run.

`output` value will be initially generated as `$HOME/yt-watcher`.

```yaml
query:
  interval: 1min
  age: 24hr
loop: true
verbose: true
output: /home/<user>/yt-watcher
channels:
- UCaYhcUwRBNscFNUKTjgPFiA
- UCrW38UKhlPoApXiuKNghuig
- UCXuqSBlHAE6Xw-yeJA0Tunw
```

To configure how videos are downloaded refer to the
[configuration](https://github.com/yt-dlp/yt-dlp#configuration) options
provided by `yt-dlp`.

## How to Use

This is built for Unix systems and probably does not work on Windows, but maybe
WSL2.


### Nix

The best way to run this application is to use
[`nix`](https://nixos.org/download.html). `Nix` will include all the
dependencies needed to run the application.

```shell
# Run from this repository directory.
nix run
# Run from remote repository.
nix run "github:siph/yt-watcher"
```

`yt-watcher` can also be ran as a systemd service, either user or system-wide,
by including either the `system` or `home-manager` modules into your
configuration.
```nix
{
    # nixos system
    nixpkgs.lib.nixosSystem = {
        modules = [
            yt-watcher.nixosModules.x86_64-linux.nixos
            { services.yt-watcher.enable = true; }
        ];
    };

    # home-manager
    home-manager.lib.homeManagerConfiguration = {
        modules = [
            yt-watcher.nixosModules.x86_64-linux.home-manager
            { services.yt-watcher.enable = true; }
        ];
    };
}
```


### Nushell

This method is not ideal as `nushell` evolves quickly and scripts can become
out-of-date very easily. Managing dependencies is also cumbersome which is why
the `Nix` method is recommended.

Dependencies:
- yt-dlp: 2023.03.04
- nushell: 0.79.0

Optional Dependencies:
- ffmpeg
- rtmpdump
- atomicparsley

```
# Pass into fresh nushell instance.
nu yt-watcher.nu

# Create environment with script shebang.
./yt-watcher.nu
```

## How it works

`yt-watcher` is a `nushell` application that queries a collection of youtube
channel RSS feeds at a given interval. Videos that haven't been downloaded and
are within the `query.age` duration will be downloaded with `yt-dlp`.

Any file in the `output` directory that contains a youtube video id will
prevent that video download from being attempted; This includes `.part` and
`.yt-dlp` files from failed download attempts alongside completed `.webm`
files.

