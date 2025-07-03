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
