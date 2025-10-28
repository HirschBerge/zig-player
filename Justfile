
set windows-shell := ["pwsh",  "-NoProfile", "-c"]


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

update-deps:
        zig fetch --save git+https://github.com/dgv/clipboard; \
        zig fetch --save git+https://github.com/vrischmann/zig-sqlite; \
        zig fetch --save git+https://github.com/rockorager/zeit; \
        echo "Updated Zig deps via zig fetch"; \
        nix run github:jcollie/zon2nix#zon2nix -- --nix=deps.nix build.zig.zon; \
        echo "Generated new deps.nix"
