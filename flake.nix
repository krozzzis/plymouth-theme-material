{
  description = "Plymouth Material You theme matching DMS (OSA) — cryptsetup password prompt";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
          system: f nixpkgs.legacyPackages.${system}
        );
    in
    {
      packages = forAllSystems (pkgs: rec {
        plymouth-theme-material = pkgs.stdenvNoCC.mkDerivation {
          pname = "plymouth-theme-material";
          version = "1.7";
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
            Description=Material You theme for OSA — cryptsetup password prompt matching DMS (rounded 12px, Inter) — static matugen colors, minimal narrow progress
            ModuleName=script

            [script]
            ImageDir=$theme
            ScriptFile=$theme/material.script
            PLYMOUTH
                        # Material You tonal surfaces: primary #e5c36c, surface #16130b,
                        # surface-container #25201a, outline #8f887a.
                        magick -size 480x200 xc:none -fill "#25201a" -stroke "#8f887a" -strokewidth 1 \
                          -draw "roundrectangle 1,1 478,198 16,16" "$theme/box.png"
                        magick -size 320x48 xc:none -fill "#16130b" -stroke "#8f887a" -strokewidth 1 \
                          -draw "roundrectangle 1,1 318,46 12,12" "$theme/entry.png"
                        magick -size 8x8 xc:none -fill "#e5c36c" -draw "circle 4,4 4,1" "$theme/bullet.png"
                        magick -size 20x20 xc:none -fill "#eae1d4" -gravity center -pointsize 14 -font "DejaVu-Sans" -annotate +0+1 "🔒" "$theme/lock.png" || \
                          magick -size 20x20 xc:none -fill "#e5c36c" -draw "circle 10,10 10,1" "$theme/lock.png"
                        # Minimal narrow progress: 320x4 gray bg, handle same size fully covering
                        magick -size 320x4 xc:none -fill "#3a3933" -draw "rectangle 0,0 320,4" "$theme/progress_box.png"
                        magick -size 320x4 xc:none -fill "#e5c36c" -draw "rectangle 0,0 320,4" "$theme/progress_bar.png"
          '';
        };
        default = plymouth-theme-material;
      });

      nixosModules.material = { pkgs, ... }: {
        boot.plymouth.themePackages = [
          self.packages.${pkgs.stdenv.hostPlatform.system}.plymouth-theme-material
        ];
      };
    };
}
