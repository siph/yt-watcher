use ../yt-watcher/config.nu [get_config]

use std assert

export def test_missing_config_is_built [] {
    let dirname = "yt-watcher"

    let test_dir = ("/tmp" | path join (random chars))
    mkdir $test_dir

    { XDG_CONFIG_HOME: $test_dir, HOME: $test_dir } | load-env

    let config = get_config
    assert ($config == (open $"($env.HOME)/($dirname)/config.yaml")) "configuration file mismatch"

    rm -r $test_dir
}

export def test_present_config_is_fetched [] {
    let dirname = "yt-watcher"

    let test_dir = ("/tmp" | path join (random chars))
    mkdir $test_dir

    { XDG_CONFIG_HOME: $test_dir, HOME: $test_dir } | load-env

    let custom_config = {
        query: {
            interval:'15min'
            age:'48hr'
            use_invidious: false
            invidious_host: 'https://vid.puffyan.us/'
        }
        loop:false
        verbose:true
        output:$"($env.HOME)/yt-watcher"
        yt-dlp: {
            config: {
                enable: false
                path:$"($env.XDG_CONFIG_HOME)/yt-dlp/config"
            }
        }
        channels:[ test ]
    }

    mkdir ($env.XDG_CONFIG_HOME | path join $dirname)
    $custom_config | to yaml | save ($env.XDG_CONFIG_HOME | path join $dirname `config.yaml`)

    let config = get_config
    assert ($config == $custom_config) "configuration file mismatch"

    rm -r $test_dir
}
