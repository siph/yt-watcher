#!/usr/bin/env nu

# Helper function for filtering data by string. Records are transposed into tables with "key" and "value" columns.
# > $env | string-search config key
def string-search [
    term: string # Search target.
    column?: string # column name. Leave blank if list.
] {
    let dayduh = $in
    if ($column == null) {
        $dayduh | where ($it| str contains $term)
    } else if ($dayduh | get-type | str contains record) {
        $dayduh | transpose key value | string-search $term $column
    } else {
        $dayduh | where ($it| get $column | str contains $term)
    }
}

# Get object type without it's contained data information.
def get-type [] {
    describe | split row '<' | get 0
}

# Query youtube for channel RSS and return table of videos with columns  [id title channel url date ]
def get-vids [
    id: string # Youtube channel ID.
] {
    let url = $"https://www.youtube.com/feeds/videos.xml?channel_id=($id)"
    (http get $url).content | string-search entry tag
        | get content
        | each { |$it|
            [
                [id title channel url date];
                [
                    ($it.1.content|get content.0)
                    ($it.3.content|get content.0)
                    ($it.5.content|get content.0.content.0)
                    ($it.4.attributes.href)
                    ($it.6.content|get content.0)
                ]
            ]
        } | flatten
}

# Query youtube for channel RSS and return table of videos posted within the last `duration` with columns [id title channel url date ]
def "get-vids new" [
    id: string # Youtube channel ID.
    --duration (-d): string = "1hr" # Filter videos uploaded within the last `duration`. Default is 1hr.
] {
    get-vids $id
        | where { |$it|
            (date now) < ($it.date | into datetime) + ($duration | into duration)
        }
}

# Get configuration or build default.
def get-config [config_path?: string] {
    let dir = (
        if ($config_path == null) {
            $"($env.XDG_CONFIG_HOME)/yt-watcher"
        } else { $config_path }
    )
    try {
        let config = (open $"($dir)/config.yaml")
        mkdir $"($config.output)"
        return $config
    } catch {
        let default_config = ({
            query: {
                interval:'1min'
                age:'24hr'
            }
            loop:true
            verbose:true
            output:($"($env.HOME)/yt-watcher")
            channels:[
                UCaYhcUwRBNscFNUKTjgPFiA
                UCrW38UKhlPoApXiuKNghuig
                UCXuqSBlHAE6Xw-yeJA0Tunw
            ]
        })
        print "Exporting default configuration..."
        mkdir $dir
        mkdir $default_config.output
        $default_config | to yaml | tee $"($dir)/config.yaml"
        return ($default_config)
    }
}

# download with `yt-dlp`.
def download [
    url: string # Youtube url
    output_folder: string # File destination
] {
    yt-dlp -q $url --paths $output_folder
}

def main [config_path?: string] {
    let config = (get-config $config_path)
    print "Started yt-watcher with config:"
    print ($config | to yaml)
    loop {
        $config.channels | each { |it|
            get-vids new $it -d $config.query.age | where { |file|
                (((ls $config.output | describe ) == nothing) or
                ((ls $config.output | string-search $"[($file.id)]" name | length ) == 0))
            } | each { |vid|
                print $vid
                download $vid.url $config.output
            }
        } | ignore
        if ($config.loop != true) { break }
        sleep ($config.query.interval | into duration)
    }
}
