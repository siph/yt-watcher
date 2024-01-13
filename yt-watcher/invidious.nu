use ./utils.nu

# Query invidious for a table of recent videos.
export def get_recent_videos [
    user_id: string,                                 # Unique youtube user id
    server_url?: string = "https://vid.puffyan.us/", # Invidious instance url including protocol.
]: nothing -> table<title: string, videoId: string, published: int> {
    http get $"($server_url)/api/v1/channels/($user_id)"
        | $in.latestVideos
        | select title videoId published
}

