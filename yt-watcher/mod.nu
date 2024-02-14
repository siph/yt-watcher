use ./youtube.nu
use ./invidious.nu
use ./config.nu [get_config]
use ./utils.nu [filter_by_age, to_url, is_completed]

use std log

# Download recent youtube videos from a list of channel ids.
export def main [
    config_path?: path, # Path to configuration file
] {
    let config = (get_config $config_path)

    log info $"Started yt-watcher with config:\n($config | to json)"

    loop {
        let recent_videos = $config.channels
            | each {|id|
                sleep 1sec

                try {
                    if $config.query.use_invidious {
                        invidious get_recent_videos $id $config.query.invidious_host
                    } else {
                        youtube get_recent_videos $id
                    }
                } catch {
                    log error $"Failed to get recent videos for channel id: ($id)"
                }
            }
            | flatten
            | filter_by_age $config.query.age
            | where (is_completed $it.videoId $config.output | not $in)

            if ($recent_videos | length) > 0 {
                log info $"New videos: ($recent_videos | to json)"
            }

            $recent_videos
                | each {|it|
                    if $config.query.use_invidious {
                        download ($it.videoId | to_url $config.query.invidious_host) $config.output $config.yt-dlp
                    } else {
                        download ($it.videoId | to_url "https://www.youtube.com") $config.output $config.yt-dlp
                    }
                }

        if ($config.loop != true) { break }

        sleep ($config.query.interval | into duration)
    }
}

def download [
    url: string           # Youtube url
    output_folder: string # File destination
    yt_dlp: record        # Yt-dlp configuration info
] {
    log info $"Download started for ($url) to ($output_folder)"
    if $yt_dlp.config.enable {
        (
            yt-dlp
                --ignore-config
                --config-locations
                $yt_dlp.config.path
                -q
                $url
                --paths
                $output_folder
        )
    } else {
        (
            yt-dlp
                -q
                $url
                --paths
                $output_folder
        )
    }
}

