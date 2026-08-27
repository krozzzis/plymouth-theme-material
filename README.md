# Plymouth Material You theme — matching DMS (OSA)

Material You Plymouth theme for OSA — cryptsetup password prompt in Material Design, repeating DMS (DankMaterialShell).

- **Name:** `material` (as requested, not `dms`)
- **Module:** `script` (rounded 12px, InterVariable, blur-like dark surface #141218 / #1C1B1F, primary #6750A4)
- **Usage (NixOS):**
  ```nix
  {
    inputs.plymouth-theme-material.url = "github:krozzzis/plymouth-theme-material";
    # ...
    boot.plymouth.theme = "material";
    boot.plymouth.themePackages = [ inputs.plymouth-theme-material.packages.${pkgs.system}.plymouth-theme-material ];
    boot.initrd.systemd.enable = true; # for systemd-ask-password via plymouth
  }
  ```
  Or via `nixosModules`:
  ```nix
  imports = [ inputs.plymouth-theme-material.nixosModules.material ];
  boot.plymouth.theme = "material";
  ```

- **OSA integration:** `osa` already provides `osa.system.plymouth` with `theme = "material"` by default, using this repo as `plymouth-theme-material` input.

Generated assets: `box.png` (520x320), `entry.png` (360x56), `bullet.png` (14x14), `lock.png` (24x24), `progress_box/bar.png` — all Material You, DMS palette.
