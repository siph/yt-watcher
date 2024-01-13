use ./utils.nu

# Query youtube for a table of recent videos.
export def get_recent_videos [
    user_id: string,                                 # Unique youtube user id
    server_url?: string = "https://www.youtube.com", # Youtube url including protocol.
]: nothing -> table<title: string, videoId: string, published: int> {
    http get $"($server_url)/feeds/videos.xml?channel_id=($user_id)"
        | get content
        | filter_content `entry`
        | each {|entry|
            {
                title: ($entry.content | filter_content `title` | extract_content)
                videoId: ($entry.content | filter_content `videoId` | extract_content)
                published: (
                    $entry.content
                        | filter_content `published`
                        | extract_content
                        | into datetime
                        | into int
                        | $in / 1_000_000_000
                )
            }
        }
}

def filter_content [tag: string]: list<record> -> list<record> {
    $in | where ($it.tag == $tag)
}

def extract_content []: list<record> -> string {
    $in | first | $in.content | first | $in.content
}
