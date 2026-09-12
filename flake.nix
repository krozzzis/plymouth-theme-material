{
  description = "A quiet graphite-and-sage Plymouth theme with Rubik typography";

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
        plymouth-theme-material = pkgs.callPackage ./package.nix { };
        default = plymouth-theme-material;
      });

      checks = forAllSystems (
        pkgs:
        let
          # NixOS normally loads plugins from /run, which is absent in a builder.
          previewPlymouth = pkgs.plymouth.overrideAttrs (old: {
            mesonFlags =
              builtins.filter (flag: !(pkgs.lib.hasPrefix "-Druntime-plugins=" flag)) old.mesonFlags
              ++ [ "-Druntime-plugins=false" ];
          });
          defaultTheme = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
          customTheme = defaultTheme.override {
            settings = {
              palette.background = "#17131e";
              palette.surface = "#241d30";
              palette.outline = "#473b56";
              palette.accent = "#cfb4f5";
              palette.inputOutline = "#cfb4f5";
              palette.input = "#17131e";
              palette.badge = "#3b2d4e";
              palette.onSurface = "#eee5f5";
              palette.muted = "#b7a8c7";
              font = "${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans.ttf";
              fontFamily = "DejaVu Sans";
              title = "Welcome to \"my device\" — unlock to continue";
              titleSize = 24;
              textSize = 12;
              cardRadius = 8;
              inputRadius = 0;
              logo = "${defaultTheme}/share/plymouth/themes/material/lock.png";
              logoSize = 32;
              logoOpacity = 0.8;
              logoBottom = 16;
              progressWidth = 240;
              progressHeight = 6;
            };
          };
          checkTheme =
            theme:
            let
              fonts = pkgs.runCommand "material-preview-font" { } ''
                mkdir -p "$out"
                cp ${pkgs.lib.escapeShellArg (toString theme.font)} "$out/"
              '';
            in
            pkgs.runCommand "material-theme-check"
              {
                nativeBuildInputs = [
                  pkgs.python3
                  pkgs.imagemagick
                ];
                FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [ fonts ]; };
                MATERIAL_BACKGROUND = theme.settings.palette.background;
                MATERIAL_CUSTOM_LOGO = if theme.settings.logo == null then "0" else "1";
              }
              ''
                    export XDG_CACHE_HOME="$TMPDIR/font-cache"
                python3 ${./check-theme.py} ${previewPlymouth}/lib/plymouth/script.so \
                ${theme}/share/plymouth/themes/material "$out"
              '';
        in
        {
          theme = checkTheme defaultTheme;
          customization = checkTheme customTheme;
        }
      );

      lib.mkTheme =
        { pkgs, ... }@args:
        pkgs.callPackage ./package.nix { settings = builtins.removeAttrs args [ "pkgs" ]; };
      nixosModules.material = import ./module.nix;
    };
}
