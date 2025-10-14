{
  description = "A Nix-flake-based Zig development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";

  outputs = { self, nixpkgs }: let
    supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    
    forEachSupportedSystem = f:
      nixpkgs.lib.genAttrs supportedSystems (system:
        f {
          pkgs = import nixpkgs {inherit system;};
        });
  in {
    devShells = forEachSupportedSystem ({pkgs}: {
      default = pkgs.mkShell {
        packages = with pkgs; [zig zls lldb];
      };
    });

    packages = forEachSupportedSystem ({pkgs}: let
      pname = "zig_player";
      version = "1.0.1";
      deps = pkgs.callPackage ./deps.nix {
        name = "${pname}-cache-${version}";
      };
    in {
      default = pkgs.stdenv.mkDerivation {
        inherit pname version;
        src = self;
        nativeBuildInputs = [pkgs.zig];

        zigBuildFlags = [
          "--system"
          "${deps}"
          "-Dversion-string=${version}"
          "-Drelease-fast"
        ];

        installPhase = ''
          mkdir -p $out/bin
          install -Dm755 ${self}/zig-out/bin/${pname} $out/bin/${pname}
          ln -s $out/bin/${pname} $out/bin/zp
        '';
      };
    });
  };
}
