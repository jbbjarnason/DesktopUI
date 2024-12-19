{
  description = "ZeroTier DesktopUI flake using buildRustPackage";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      packages.${system}.desktopui = pkgs.rustPlatform.buildRustPackage rec {
        pname = "zerotier-desktop-ui";
        version = (fromTOML (builtins.readFile ./Cargo.toml)).package.version;

        src = self;

        cargoLock = {
          lockFile = ./Cargo.lock;
          allowBuiltinFetchGit = true;
        };

        nativeBuildInputs = [
          pkgs.meson
          pkgs.ninja
          pkgs.pkg-config
          pkgs.gnumake
        ];

        buildInputs = [
          pkgs.gcc
          pkgs.zlib
          pkgs.freetype
          pkgs.fontconfig
          pkgs.gtk3
          pkgs.libappindicator
        ];
        buildPhase = ''
          cargo build --release
        '';

        configurePhase = ''
          echo "=== Building libui-ng ==="
          cd libui-ng
          meson setup build --buildtype=release --default-library=static --backend=ninja
          ninja -C build
          cd ..

          echo "=== Building tray ==="
          cd tray
          make clean
          make zt_lib
          cd ..
        '';

        installPhase = ''
          mkdir -p $out/bin
          cp target/release/zerotier_desktop_ui $out/bin/
          # Todo install .desktop file
        '';

        meta = with pkgs.lib; {
          homepage = "https://github.com/zerotier/DesktopUI";
          description = "ZeroTier Desktop UI";
          license = licenses.mpl20;
          platforms = platforms.linux;
        };
      };
    };
}
