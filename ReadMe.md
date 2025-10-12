# Zig Player

## Vision
It's not going to be an actual video player or anything. Probably just MPV.
### Core Features
I want it to replace my [yt script](https://github.com/HirschBerge/Public-dots/blob/6637b5845ac1d88f7d75b11905e2c7e311b38e13/nixos/common/scripts.nix#L79). I'd like to incorporate a few things.

- [/] History: ~~Probably just stored in a json in $XDG_CACHE_HOM~~ SQLite
 - [-] Structure for sqlite db
 - [-] Time
 - [-] Url
 - [ ] Channel
 - [ ] Title
 - [ ] Length
- [ ] Parse metadata from yt-dlp
- [ ] Replay/queue items from history.
 - [ ] Create query for
  - [ ] Last video played
  - [ ] All history, but maybe a fuzzy finder?
- [ ] Notifications
- [ ] Quick rewatch last
- [ ] Show mpv queue
- [I] Maybe have built-in queue in case I want to support other players such as vlc?

## Install and build

```bash
jj git clone (wl-paste) # Copy to clipboard
cd ./zig_player
zig init # Generates build filers for your platform
zig fetch --save git+https://github.com/dgv/clipboard
zig fetch --save git+https://github.com/vrischmann/zig-sqlite
zig fetch --save git+https://github.com/rockorager/zeit
zig build run --release=fast
```
