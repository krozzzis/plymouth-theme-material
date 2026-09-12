{ lib, pkgs }:
let
  inherit (lib) mkOption types;
  color =
    default:
    mkOption {
      type = types.strMatching "#[0-9a-fA-F]{6}";
      inherit default;
      description = "RGB color in #rrggbb notation.";
    };
  integer =
    default: min: max: description:
    mkOption {
      type = types.ints.between min max;
      inherit default description;
    };
in
{
  palette = mkOption {
    default = { };
    description = "Partial overrides of the graphite and sage palette.";
    type = types.submodule {
      options = {
        background = color "#0f1413";
        surface = color "#19221e";
        outline = color "#303e35";
        accent = color "#b9d6bf";
        onSurface = color "#e8f0e8";
        muted = color "#a8b8ad";
        input = color "#0f1413";
        inputOutline = color "#9fbea5";
        badge = color "#2b3e30";
      };
    };
  };
  font = mkOption {
    type = types.path;
    default = "${pkgs.rubik}/share/fonts/truetype/Rubik-Regular.ttf";
    description = "Font file copied into the initrd by the NixOS module.";
  };
  fontFamily = mkOption {
    type = types.nonEmptyStr;
    default = "Rubik";
    description = "Pango family name matching the selected font file.";
  };
  title = mkOption {
    type = types.nonEmptyStr;
    default = "Unlock your device";
    description = "Heading above the system-provided disk prompt.";
  };
  passwordHint = mkOption {
    type = types.nonEmptyStr;
    default = "Enter your disk passphrase";
    description = "Fallback when the password agent supplies no prompt.";
  };
  titleSize = integer 20 8 32 "Heading font size in points; long headings are fitted to the card.";
  textSize = integer 11 8 24 "Prompt and message font size in points.";
  cardRadius = integer 28 0 64 "Card corner radius in pixels.";
  inputRadius = integer 16 0 28 "Password field corner radius in pixels.";
  logo = mkOption {
    type = types.nullOr types.path;
    default = null;
    description = "Optional image bundled with the theme; null uses the system Plymouth logo.";
  };
  showLogo = mkOption {
    type = types.bool;
    default = true;
    description = "Show the footer logo.";
  };
  logoSize = integer 48 16 96 "Maximum footer logo width and height, preserving its aspect ratio.";
  logoBottom = integer 32 0 64 "Footer margin in pixels.";
  logoOpacity = mkOption {
    type = types.numbers.between 0 1;
    default = 0.55;
    description = "Footer logo opacity.";
  };
  progressWidth = integer 320 80 432 "Centered progress track width in pixels.";
  progressHeight = integer 4 1 6 "Borderless progress track height in pixels.";
}
