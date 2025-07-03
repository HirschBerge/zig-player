run:
        zig build run --release=fast

build:
        zig build --release=fast

no-build:
        ./zig-out/bin/zig_player
test:
        zig build test
