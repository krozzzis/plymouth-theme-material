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
          version = "1.1";
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
Description=Material You theme for OSA — cryptsetup password prompt matching DMS (rounded 12px, Inter, blur-like) — static matugen colors
ModuleName=script

[script]
ImageDir=$theme
ScriptFile=$theme/material.script
PLYMOUTH
            # Material You static colors from current matugen (dms-colors.json dark): primary #e5c36c, surface #16130b, container #231f17, outline #989080
            magick -size 520x320 xc:none -fill "#16130b" -stroke "#e5c36c" -strokewidth 2 \
              -draw "roundrectangle 2,2 518,318 16,16" "$theme/box.png"
            magick -size 360x56 xc:none -fill "#231f17" -stroke "#e5c36c" -strokewidth 1.5 \
              -draw "roundrectangle 1,1 359,55 12,12" "$theme/entry.png"
            magick -size 14x14 xc:none -fill "#e5c36c" -draw "circle 7,7 7,1" "$theme/bullet.png"
            magick -size 24x24 xc:none -fill "#eae1d4" -gravity center -pointsize 16 -font "DejaVu-Sans" -annotate +0+2 "🔒" "$theme/lock.png" || \
              magick -size 24x24 xc:none -fill "#e5c36c" -draw "circle 12,12 12,2" "$theme/lock.png"
            # wave-like progress: base box + wavy bar (we generate a wavy bar via gradient + wave pattern)
            magick -size 400x20 xc:none -fill "#231f17" -draw "roundrectangle 0,0 400,20 10,10" "$theme/progress_box.png"
            # wavy bar: primary #e5c36c with subtle wave (using plasma or sine)
            magick -size 398x16 xc:none -fill "#e5c36c" -draw "roundrectangle 0,0 398,16 8,8" "$theme/progress_bar.png"
            # alternative wave pattern for progress (for wave animation)
            magick -size 400x20 xc:none -fill none -stroke "#e5c36c" -strokewidth 2 -draw "path 'M 0,10 Q 10,0 20,10 T 40,10 T 60,10 T 80,10 T 100,10 T 120,10 T 140,10 T 160,10 T 180,10 T 200,10 T 220,10 T 240,10 T 260,10 T 280,10 T 300,10 T 320,10 T 340,10 T 360,10 T 380,10 T 400,10'" "$theme/progress_wave.png" || cp "$theme/progress_bar.png" "$theme/progress_wave.png"
          '';
        };
        default = plymouth-theme-material;
      });

      nixosModules.material = { pkgs, ... }: {
        boot.plymouth.themePackages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.plymouth-theme-material ];
      };
    };
}
