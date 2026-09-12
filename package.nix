{
  lib,
  stdenvNoCC,
  imagemagick,
  replaceVars,
  rubik,
  settings ? { },
}:
let
  cfg =
    (lib.evalModules {
      modules = [
        {
          options = import ./options.nix {
            inherit lib;
            pkgs = { inherit rubik; };
          };
        }
        { config = settings; }
      ];
    }).config;
  p = cfg.palette;
  digit =
    c: lib.lists.findFirstIndex (x: x == lib.toLower c) 0 (lib.stringToCharacters "0123456789abcdef");
  channel =
    hex: offset:
    toString (
      (16 * digit (builtins.substring offset 1 hex) + digit (builtins.substring (offset + 1) 1 hex))
      / 255.0
    );
  rgb =
    hex:
    lib.concatMapStringsSep ", " (channel hex) [
      1
      3
      5
    ];
  script = replaceVars ./theme/material.script {
    background = rgb p.background;
    foreground = rgb p.onSurface;
    muted = rgb p.muted;
    title = builtins.toJSON cfg.title;
    passwordHint = builtins.toJSON cfg.passwordHint;
    titleFont = builtins.toJSON "${cfg.fontFamily} ${toString cfg.titleSize}";
    textFont = builtins.toJSON "${cfg.fontFamily} ${toString cfg.textSize}";
    logo = if cfg.logo == null then "special://logo" else "logo.png";
    logoSize = toString cfg.logoSize;
    logoOpacity = if cfg.showLogo then toString cfg.logoOpacity else "0";
    logoBottom = toString cfg.logoBottom;
  };
in
stdenvNoCC.mkDerivation {
  pname = "plymouth-theme-material";
  version = "2.0";
  dontUnpack = true;
  nativeBuildInputs = [ imagemagick ];
  passthru = {
    inherit (cfg) font;
    settings = cfg;
  };
  installPhase = ''
    theme="$out/share/plymouth/themes/material"
    mkdir -p "$theme"
    cp ${script} "$theme/material.script"
    cat > "$theme/material.plymouth" <<PLYMOUTH
    [Plymouth Theme]
    Name=Material
    Description=Centered unlock card with configurable colors and typography
    ModuleName=script

    [script]
    ImageDir=$theme
    ScriptFile=$theme/material.script
    PLYMOUTH
    # Supersample rounded surfaces and the geometric lock for clean edges.
    magick -size 1728x1152 xc:none -fill '${p.surface}' -stroke '${p.outline}' -strokewidth 4 \
      -draw '${
        if cfg.cardRadius == 0 then
          "rectangle 2,2 1726,1150"
        else
          "roundrectangle 2,2 1726,1150 ${toString (cfg.cardRadius * 4)},${toString (cfg.cardRadius * 4)}"
      }' -resize 432x288 "$theme/box.png"
    magick -size 1472x224 xc:none -fill '${p.input}' -stroke '${p.inputOutline}' -strokewidth 4 \
      -draw '${
        if cfg.inputRadius == 0 then
          "rectangle 2,2 1470,222"
        else
          "roundrectangle 2,2 1470,222 ${toString (cfg.inputRadius * 4)},${toString (cfg.inputRadius * 4)}"
      }' -resize 368x56 "$theme/entry.png"
    magick -size 32x32 xc:none -fill '${p.accent}' -draw 'circle 16,16 16,2' -resize 8x8 "$theme/bullet.png"
    # Material Symbols-inspired keyboard_capslock, supersampled for clean edges.
    magick -size 96x96 xc:none -fill none -stroke '${p.accent}' -strokewidth 8 \
      -draw "path 'M 20,52 L 48,24 L 76,52 M 24,72 L 72,72'" \
      -resize 24x24 "$theme/capslock.png"
    magick -size 224x224 xc:none -fill '${p.badge}' \
      -draw 'circle 112,112 112,2' -fill none -stroke '${p.accent}' -strokewidth 8 \
      -draw "path 'M 80,104 L 80,80 C 80,40 144,40 144,80 L 144,104'" \
      -fill '${p.accent}' -stroke none -draw 'roundrectangle 64,96 160,164 16,16' \
      -fill '${p.badge}' -draw 'circle 112,126 112,119' \
      -draw 'roundrectangle 109,126 115,143 3,3' -resize 56x56 "$theme/lock.png"
    magick -size ${toString cfg.progressWidth}x${toString cfg.progressHeight} xc:'${p.outline}' "$theme/progress_track.png"
    magick -size ${toString cfg.progressWidth}x${toString cfg.progressHeight} xc:'${p.accent}' "$theme/progress_bar.png"
    ${lib.optionalString (cfg.logo != null) ''
      magick ${lib.escapeShellArg (toString cfg.logo)} -resize '${toString cfg.logoSize}x${toString cfg.logoSize}>' "$theme/logo.png"
    ''}
  '';
}
