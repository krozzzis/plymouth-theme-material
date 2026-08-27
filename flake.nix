{
  description = "Plymouth Material You theme matching DMS (OSA) — cryptsetup password prompt";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      forAllSystems = f: nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        plymouth-theme-material = pkgs.stdenvNoCC.mkDerivation {
          pname = "plymouth-theme-material";
          version = "1.2";
          src = ./theme;
          dontUnpack = true;
          nativeBuildInputs = [ pkgs.imagemagick ];
          installPhase = ''
            theme="$out/share/plymouth/themes/material"
            mkdir -p "$theme"
            cp $src/material.script "$theme/material.script"
            cat > "$theme/material.plymouth" <<PLYMOUTH
[Plymouth Theme]
Name=Material
Description=Material You theme for OSA — cryptsetup password prompt matching DMS (rounded 12px, Inter) — static matugen colors, minimal 4px progress
ModuleName=script

[script]
ImageDir=$theme
ScriptFile=$theme/material.script
PLYMOUTH
            # Material You static colors: primary #e5c36c, surface #16130b, container #231f17
            # box: 520x320 rounded 16, no border handling in script, entry: 360x56 no border, bullet 14, lock 24, progress minimal 400x4
            magick -size 520x320 xc:none -fill "#16130b" -draw "roundrectangle 2,2 518,318 16,16" "$theme/box.png"
            magick -size 360x56 xc:none -fill "#231f17" -draw "roundrectangle 1,1 359,55 12,12" "$theme/entry.png"
            magick -size 14x14 xc:none -fill "#e5c36c" -draw "circle 7,7 7,1" "$theme/bullet.png"
            magick -size 24x24 xc:none -fill "#eae1d4" -gravity center -pointsize 16 -font "DejaVu-Sans" -annotate +0+2 "🔒" "$theme/lock.png" || \
              magick -size 24x24 xc:none -fill "#e5c36c" -draw "circle 12,12 12,2" "$theme/lock.png"
            # Minimal progress: 400x4 gray bg, handle same size fully covering
            magick -size 400x4 xc:none -fill "#3a3933" -draw "rectangle 0,0 400,4" "$theme/progress_box.png"
            magick -size 400x4 xc:none -fill "#e5c36c" -draw "rectangle 0,0 400,4" "$theme/progress_bar.png"
          '';
        };
        default = plymouth-theme-material;
      });

      nixosModules.material = { pkgs, ... }: {
        boot.plymouth.themePackages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.plymouth-theme-material ];
      };
    };
}
