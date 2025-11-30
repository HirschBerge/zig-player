def rewatch [ ] {
        yt_history | uniq-by title |sort-by time --reverse | sk --format {get title} --preview {} | wl-copy $in.url
                zig_player
                print "Rewatching!"
}

# NOTE: Requires the `sk` plugin for nushell (https://github.com/idanarye/nu_plugin_skim)
def yt_history [] {
        open ~/.cache/zig_player/history.db
                | get history
                | each { |video|
                        if $video.length == "NA" {
                                update cells --columns [length] { '00:00:00' } #NOTE: Sets a default value in case zig_player was made to run on a livestream
                        } else {
                                $video
                        }
                }
        | update cells --columns [time] { into datetime }
        | update cells --columns [title] { str substring 0..49 }
        | update cells --columns [length] {
                let $parts = split column ':' hours minutes seconds
                        | update cells -c [hours minutes seconds] { into int };
                (($parts.hours | first) * 3600) + (($parts.minutes | first) * 60) + ($parts.seconds | first)
                        | into duration --unit sec
        }
        | select time length channel title url
}
