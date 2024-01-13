use std log

# Filter out results older than `threshold`
export def filter_by_age [
    threshold?: duration, # Videos newer than `threshold` will be returned
]: table<title: string, videoId: string, published: int> -> table<title: string, videoId: string, published: int> {
    $in | if ($threshold == null) { $in } else {
            where (($it.published * 1_000_000_000 | into datetime) > (date now) - ($threshold | into duration))
        }
}

# Checks if a video has been fully downloaded
export def is_completed [
    id: string,   # Video id
    output: path, # Working directory
]: nothing -> bool {
    ls $output
        | reduce --fold false {|val, acc| $acc or (
            ($val.name | str contains $id) and ($val.name | path parse | $in.extension == `part`| not $in)
        )}
}

# Convert video id to url
export def to_url [
    base_url: string, # Base url including protocol
]: string -> string {
    $"($base_url)/watch?v=($in)"
}
