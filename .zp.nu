def gen_path [ ] {
  match $nu.os-info.name {
    "linux" => { $"($env.HOME)/.cache/zig_player/history.db" },
    "macos" => { $"($env.HOME)/.cache/zig_player/history.db"},
    "windows" => { $"($env.LOCALAPPDATA)/zig_player/history.db" },
    _ => { "Error: Unsupported OS" }
  }
}

def paste_to_clip [ url: string ] {
  match $nu.os-info.name {
    "linux" => { wl-copy $url },
    "macos" => { pbcopy $url },
    "windows" => { "pwsh.exe -NoProfile -Command 'Set-Clipboard $url'" },
    _ => { "Error: Unsupported OS" }
  }
}
def yt_history [ --url (-u) = false] {
    let $history = open (gen_path)
    | get history
    | each { |video|
        if $video.length == "NA" {
            update cells --columns [length] { '00:00:00' }
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
    if $url { 
    $history  | select time length channel title url
  } else { 
    $history  | select time length channel title
  }
  
}

def rewatch [ ] {
    yt_history --url true| uniq-by title |sort-by time --reverse | sk --format {get title} --preview {} | $in.url |
    zig_player
    print "Rewatching!"
}
# NOTE: Requires the `sk` plugin for nushell (https://github.com/idanarye/nu_plugin_skim)
