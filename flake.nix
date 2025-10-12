{
  description = "A Nix-flake-based Zig development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Pre-fetch all dependencies listed in your build.zig.zon
    # This must be kept in sync with your .zon file
    clipboard = {
      url = "github:dgv/clipboard/0ba2e06f3ade58237a45c4f3321884dee2aba775";
      flake = false;
    };
    sqlite = {
      url = "github:vrischmann/zig-sqlite/6d90ee900d186a7fbb6066f28ee13beeaf8be345";
      flake = false;
    };
    zeit = {
      url = "github:rockorager/zeit/74be5a2afb346b2a6a6349abbb609e89ec7e65a6";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    # This function creates the necessary override flags for zig build
    zigDeps = builtins.concatStringsSep " " (
      map (depName: ''--override-lib ${depName}=${inputs.${depName}}'')
      # ⚠️ This list of names MUST match the names in your build.zig.zon
      ["clipboard" "sqlite" "zeit"]
    );

    supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forEachSupportedSystem = f:
      nixpkgs.lib.genAttrs supportedSystems (system:
        f {
          pkgs = import nixpkgs {inherit system;};
        });
  in {
    devShells = forEachSupportedSystem ({pkgs}: {
      default = pkgs.mkShell {
        packages = with pkgs; [zig zls lldb just];
      };
    });

    packages = forEachSupportedSystem ({pkgs}: let
      pname = "zig_player";
      version = "0.5.0";
    in {
      default = pkgs.stdenv.mkDerivation {
        inherit pname version;
        src = self;
        nativeBuildInputs = [pkgs.zig];

        buildPhase = ''
          export ZIG_GLOBAL_CACHE_DIR="$PWD/.zig-cache"
          zig build -Drelease-fast ${zigDeps}
        '';

        installPhase = ''
          mkdir -p $out/bin
          install -Dm755 zig-out/bin/${pname} $out/bin/${pname}
          ln -s $out/bin/${pname} $out/bin/zp
        '';
      };
    });
  };
}
