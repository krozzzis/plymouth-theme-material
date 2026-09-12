{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.boot.plymouth.material;
  theme = pkgs.callPackage ./package.nix { inherit (cfg) settings; };
in
{
  options.boot.plymouth.material.settings = lib.mkOption {
    default = { };
    description = "Material theme appearance. Unspecified values use graphite and sage defaults.";
    type = lib.types.submodule {
      options = import ./options.nix { inherit lib pkgs; };
    };
  };
  config = {
    boot.plymouth.theme = lib.mkDefault "material";
    boot.plymouth.themePackages = [ theme ];
    boot.plymouth.font = lib.mkDefault theme.font;
  };
}
