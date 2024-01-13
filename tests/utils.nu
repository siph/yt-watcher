use ../yt-watcher/utils.nu [to_url, is_completed]

use std assert

export def test_id_to_url [] {
    let expected = "https://www.youtube.com/watch?v=tL3sTsH4_To"
    let result = "tL3sTsH4_To" | to_url "https://www.youtube.com"
    assert ($expected == $result)
}

export def test_is_completed [] {
    let test_dir = ("/tmp" | path join (random chars))
    mkdir $test_dir

    touch ($test_dir | path join "[done_id].mkv")
    touch ($test_dir | path join "[part_id].mkv.part")

    assert (is_completed "done_id" $test_dir)
    assert (is_completed "part_id" $test_dir | not $in)
    assert (is_completed "unfound" $test_dir | not $in)

    rm -r $test_dir
}
