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
          version = "1.0";
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
Description=Material You theme for OSA — cryptsetup password prompt matching DMS (rounded 12px, Inter, blur-like)
ModuleName=script

[script]
ImageDir=$theme
ScriptFile=$theme/material.script
PLYMOUTH
            magick -size 520x320 xc:none -fill "#1C1B1F" -stroke "#6750A4" -strokewidth 2 \
              -draw "roundrectangle 2,2 518,318 16,16" "$theme/box.png"
            magick -size 360x56 xc:none -fill "#2B2930" -stroke "#6750A4" -strokewidth 1.5 \
              -draw "roundrectangle 1,1 359,55 12,12" "$theme/entry.png"
            magick -size 14x14 xc:none -fill "#6750A4" -draw "circle 7,7 7,1" "$theme/bullet.png"
            magick -size 24x24 xc:none -fill "#CAC4D0" -gravity center -pointsize 16 -font "DejaVu-Sans" -annotate +0+2 "🔒" "$theme/lock.png" || \
              magick -size 24x24 xc:none -fill "#CAC4D0" -draw "circle 12,12 12,2" "$theme/lock.png"
            magick -size 400x20 xc:none -fill "#2B2930" -draw "roundrectangle 0,0 400,20 10,10" "$theme/progress_box.png"
            magick -size 398x16 xc:none -fill "#6750A4" -draw "roundrectangle 0,0 398,16 8,8" "$theme/progress_bar.png"
          '';
        };
        default = plymouth-theme-material;
      });

      nixosModules.material = { pkgs, ... }: {
        boot.plymouth.themePackages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.plymouth-theme-material ];
      };
    };
}
