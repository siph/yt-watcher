# yt-watcher

`yt-watcher` allows users to monitor a list of YouTube channels and
automatically download their most recent videos. This tool simplifies the
process of keeping track of your favorite content creators without compromising
on privacy or needing to suffer through ads.

This can be configured to use either the YouTube, or
[`Invidious`](https://invidious.io/) api.


## Configuration

`config.yaml` can be found in `XDG_HOME`. For linux this is typically
`~/.config/yt-watcher`. A default configuration is generated on first run.

`output` value will be initially generated as `$HOME/yt-watcher`.

```yaml
query:
  interval: 1min
  age: 24hr
  use_invidious: false
  invidious_host: https://vid.puffyan.us/
loop: true
verbose: true
output: /home/<user>/yt-watcher
channels:
- UCaYhcUwRBNscFNUKTjgPFiA
- UCrW38UKhlPoApXiuKNghuig
```

To configure how videos are downloaded refer to the
[configuration](https://github.com/yt-dlp/yt-dlp#configuration) options
provided by `yt-dlp`.

## How to Use

### Nix

The best way to run this application is to use
[`nix`](https://nixos.org/download.html). `Nix` will include all the
dependencies needed to run the application.

```shell
# Run from remote repository.
nix run "github:siph/yt-watcher"

# With custom configuration file location
nix run "github:siph/yt-watcher" -- ./config.yaml
```

### Nushell

This method is not ideal as `nushell` evolves quickly and scripts can become
out-of-date very easily. Managing dependencies is also cumbersome which is why
the `Nix` method is recommended.

Dependencies:
- yt-dlp: 2023.12.30
- nushell: 0.88.1

Optional Dependencies:
- ffmpeg
- rtmpdump
- atomicparsley

```shell
nu \
--no-config-file \
--commands 'use ./yt-watcher ; yt-watcher'
```
