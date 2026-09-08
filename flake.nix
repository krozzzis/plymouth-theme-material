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
          version = "1.5";
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
            Description=Material You theme for OSA — cryptsetup password prompt matching DMS (Material You guidelines)
            ModuleName=script

            [script]
            ImageDir=$theme
            ScriptFile=$theme/material.script
            PLYMOUTH
                        # Material You dark scheme: primary #b8f3b1, surface #10140f,
                        # surface-container #1d281e, outline #879587.
                        magick -size 520x224 xc:none \
                          -fill "#1d281e" -stroke "#485849" -strokewidth 1 \
                          -draw "roundrectangle 1,1 518,222 28,28" "$theme/box.png"
                        magick -size 364x56 xc:none \
                          -fill "#152016" -stroke "#879587" -strokewidth 1 \
                          -draw "roundrectangle 1,1 362,54 16,16" "$theme/entry.png"
                        magick -size 8x8 xc:none -fill "#b8f3b1" -draw "circle 4,4 4,1" "$theme/bullet.png"
                        magick -size 24x24 xc:none -fill "#b8f3b1" \
                          -draw "roundrectangle 6,10 18,20 3,3" \
                          -fill none -stroke "#b8f3b1" -strokewidth 2 \
                          -draw "path 'M 8,10 C 8,4 16,4 16,10'" "$theme/lock.png"
                        magick -size 16x16 xc:none -fill "#ffb4ab" -draw "circle 8,8 8,1" "$theme/capslock.png"
                        magick -size 320x6 xc:none -fill "#364637" \
                          -draw "roundrectangle 0,0 319,5 3,3" "$theme/progress_box.png"
                        magick -size 320x6 xc:none -fill "#b8f3b1" \
                          -draw "roundrectangle 0,0 319,5 3,3" "$theme/progress_bar.png"
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
