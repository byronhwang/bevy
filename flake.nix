{
  description = "A basic Nix flake providing development shells";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-stable.follows = "nixpkgs";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-v2505.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-v2411.url = "github:NixOS/nixpkgs/nixos-24.11";
    nur = {
      url = "github:nix-community/NUR";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      nixpkgs-unstable,
      nixpkgs-v2505,
      nixpkgs-v2411,
      nur,
      ...
    }@inputs:
    let
      pkg-settings = rec {
        allowed-unfree-packages =
          pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "cudnn"
            "libcublas"
          ];
        allowed-insecure-packages = [
          "electron-11.5.0"
          "openssl-1.1.1w"
        ];
      };

      eachSystem = nixpkgs.lib.genAttrs [ "x86_64-linux" ] (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfreePredicate = pkg-settings.allowed-unfree-packages;
            config.permittedInsecurePackages = pkg-settings.allowed-insecure-packages;
            overlays = [
              nur.overlays.default
              (final: prev: {
                unstable = import nixpkgs-unstable {
                  inherit system;
                  config.allowUnfreePredicate = pkg-settings.allowed-unfree-packages;
                  config.permittedInsecurePackages = pkg-settings.allowed-insecure-packages;
                  overlays = [ nur.overlays.default ];
                };
              })
              (final: prev: {
                v2505 = import nixpkgs-v2505 {
                  inherit system;
                  config.allowUnfreePredicate = pkg-settings.allowed-unfree-packages;
                  config.permittedInsecurePackages = pkg-settings.allowed-insecure-packages;
                  overlays = [ nur.overlays.default ];
                };
              })
              (final: prev: {
                v2411 = import nixpkgs-v2411 {
                  inherit system;
                  config.allowUnfreePredicate = pkg-settings.allowed-unfree-packages;
                  config.permittedInsecurePackages = pkg-settings.allowed-insecure-packages;
                  overlays = [ nur.overlays.default ];
                };
              })
            ];
          };
        in
        {
          default = pkgs.mkShellNoCC {
            name = "cppm";
            hardeningDisable = [ "fortify" ];
            packages = with pkgs; [
              pkg-config
              bear
              gnumake
              ninja
              cmake
              xmake

              boost
              spdlog
              fmt
              cli11
              cpptrace
              gtest
              gbenchmark

              llvmPackages_20.clangNoLibcxx
              gcc15
              gdb
              python314

              bzip2
              zlib
              zip
              libdwarf

              assimp
              eigen
              ffmpeg_7
              freetype
              glew
              glfw
              glm
              libGL
              vulkan-loader
              python313Packages.glad
              xorg.libX11
              xorg.libXrandr
              xorg.libXinerama
              xorg.libXi
              xorg.libXxf86vm
              xorg.libXcursor
              xorg.xorgproto
              libxkbcommon
              # (opencv.override {
              #   enableGtk2 = true;
              #   enableGtk3 = true;
              #   enableFfmpeg = true;
              #   enablePython = false;
              #   enableContrib = true;
              # })

              SDL2
              SDL2_gfx
              SDL2_net
              SDL2_mixer
              SDL2_ttf
              SDL2_sound
              SDL2_image
              SDL2_Pango

              sdl3
              sdl3-image
              sdl3-ttf

              qt6.qtbase
              qt6.qtmultimedia
              qt6.qtdeclarative
              qt6.qttools
              qt6.qtnetworkauth
              qt6.qtwebchannel
              qt6.qtpositioning
              qt6.qt5compat
              qt6.qtsensors
              qt6.qtserialport
              qt6.qtremoteobjects
              qt6.qtimageformats
              qt6.qtsvg
              qt6.qtscxml
              qt6.qtwayland

              gtk2
              gtk3
              gtk4

              stb
              flac

              dotnet-sdk_11
              dotnet-runtime_11

              icu
              alsa-lib
            ];
            shellHook = ''
              # for vscode
              ln -sf "${pkgs.gdb}/bin/gdb" ./.vscode/gdb

              # Add library paths for runtime linking
              export LD_LIBRARY_PATH=${pkgs.libxkbcommon}/lib:$LD_LIBRARY_PATH
              export LD_LIBRARY_PATH=${pkgs.libGL}/lib:$LD_LIBRARY_PATH
              export LD_LIBRARY_PATH=${pkgs.glfw}/lib:$LD_LIBRARY_PATH
            '';
          };
        }
      );
    in
    {
      devShells = eachSystem;
    };
}
