use std log

# Get or create configuration file from `path`. If no path is provided,
# `$env.XDG_CONFIG_HOME` is used to determine the configuration file path.
export def get_config [
    config_file_path?: path
]: nothing -> record<query: record,loop: bool,verbose: bool, output: string, channels: list<string>> {
    let config_file = (
        if ($config_file_path == null) {
            $"($env.XDG_CONFIG_HOME)/yt-watcher/config.yaml"
        } else { $config_file_path }
    )

    try {
        let config = open $config_file
        mkdir $config.output
        return $config
    } catch {
        let default_config = {
            query: {
                interval:'1min'
                age:'24hr'
                use_invidious: false
                invidious_host: 'https://vid.puffyan.us/'
            }
            loop:true
            verbose:true
            output:$"($env.HOME)/yt-watcher"
            yt-dlp: {
                config: {
                    enable: false
                    path:$"($env.XDG_CONFIG_HOME)/yt-dlp/config"
                }
            }
            channels:[
                UCaYhcUwRBNscFNUKTjgPFiA
                UCrW38UKhlPoApXiuKNghuig
            ]
        }

        log warning "Exporting default configuration..."
        mkdir $"($env.XDG_CONFIG_HOME)/yt-watcher"
        mkdir $default_config.output
        $default_config | to yaml | save $config_file

        return $default_config
    }
}
