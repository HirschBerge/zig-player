let os_name = $nu.os-info.name
let history_path = match $os_name {
  "windows" => {
    $env.LOCALAPPDATA |path join "zig_player\\history.db"
  }
  "linux" => {
    $env.HOME | path join ".cache/zig_player/history.db"
  }
  "macos" => {
    $env.HOME | path join ".cache/zig_player/history.db"
  }
  _ =>  {
    error make {msg: PANIC, }
  }
}

# NOTE: Requires the `sk` plugin for nushell (https://github.com/idanarye/nu_plugin_skim)
def rewatch [ ] {
  match $os_name { 
    "windows" => {
      let $url = yt_history --url |sort-by time --reverse | to csv | gum table --separator=',' --return-column=5
      pwsh -NoProfile -command $"Set-Clipboard ($url)"
      ~/.scripts/zig-player/zig-out/bin/zig_player.exe
    },
    _ => {
      yt_history --url | uniq-by title |sort-by time --reverse | sk --format {get title} --preview {} | wl-copy $in.url
      zig_player
    }
  }
  print "Rewatching!"
}

def yt_history [ --url ] {
  let hist = open $history_path
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
  if ( $url == true) {
    $hist | select time length channel title url |str trim
  } else {
    $hist| select time length channel title |str trim
  }
}
