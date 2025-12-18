# Zig Player

## Vision
It's not going to be an actual video player or anything. Probably just MPV.
### Core Features
I want it to replace my [yt script](https://github.com/HirschBerge/Public-dots/blob/6637b5845ac1d88f7d75b11905e2c7e311b38e13/nixos/common/scripts.nix#L79). I'd like to incorporate a few things.

- [X] History: ~~Probably just stored in a json in $XDG_CACHE_HOM~~ SQLite
 - [X] Structure for sqlite db
 - [X] Time
 - [X] Url
 - [X] Channel
 - [X] Title
 - [X] Length
- [X] Parse metadata from yt-dlp
- [ ] Replay/queue items from history.
  - [x] Completed via provided nushell function. See below
  - [ ] Create query for
      - [?] Last video played
      - [X] All history - Nushell `rewatch`
- [ ] Notifications
- [ ] Quick rewatch last
- [X] Show mpv queue - Playlist keybind in MPV
- [I] Maybe have built-in queue in case I want to support other players such as vlc?
  - [X] Queue! On Unix system, zp will detect if mpv is already playing and use a socket to add video to your playlist (end).
  - [!] Might See how viable this method is for Windows.

## Install and build

```bash
jj git clone (wl-paste) # Copy to clipboard
cd ./zig_player
just build
```
## Running
Requires [just](https://github.com/casey/just) to be installed
```makefile
run:
        zig build run --release=fast
debug:
        zig build run
build:
        zig build --release=fast

no-build:
        ./zig-out/bin/zig_player
test:
        zig build test
```
Or you can always run your favorite zig build commands!
# Nushell Helpers
Sorry if you use other shells, Nushell is just more useful! It is cross-platform, so windows users get to partake!
I have provided a couple handy functions baed around reading the Sqlite history db.
```nu
source /path/to/.zp.nu # This can be anywhere. I recommend adding this to your $nu.config-path file
yt_history
╭────┬──────────────┬─────────────────┬───────────────────────────────────────┬────────────────────────────────────────────────────┬─────────────────────────────────────────────╮
│  # │     time     │     length      │                channel                │                       title                        │                     url                     │
├────┼──────────────┼─────────────────┼───────────────────────────────────────┼────────────────────────────────────────────────────┼─────────────────────────────────────────────┤
│  0 │ 3 months ago │       2min 4sec │ Bruh Ch.                              │ Saba: 'IT'S FAKE! DON'T CLIP IT!' Chat:            │ https://www.youtube.com/watch?v=VplCCtEouJQ │
│  1 │ 3 months ago │      9min 17sec │ ThePrimeTime                          │ THIS IS THE REAL VIBE CODING                       │ https://www.youtube.com/watch?v=tKHEEC-CBYY │
├────┼──────────────┼─────────────────┼───────────────────────────────────────┼────────────────────────────────────────────────────┼─────────────────────────────────────────────┤
│  # │     time     │     length      │                channel                │                       title                        │                     url                     │
╰────┴──────────────┴─────────────────┴───────────────────────────────────────┴────────────────────────────────────────────────────┴─────────────────────────────────────────────╯
rewatch
# I wont show output since it's just a skim tui on the back end, but you can fuzzy search
```
