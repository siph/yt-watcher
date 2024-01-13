use ../yt-watcher/invidious.nu [get_recent_videos]

use std assert

export def test_videos_are_fetched [] {
    let videos = get_recent_videos `test-id` `http://localhost:8080`
    assert (($videos | length) > 0)
}
