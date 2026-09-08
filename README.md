# Plymouth Material You theme for OSA

Material You Plymouth theme for OSA. It provides a calm dark boot screen, a
tonal unlock card, compact password bullets, and a low-profile progress bar.
The Script implementation contains only Plymouth Script syntax, so it loads
instead of falling back to a firmware logo.

- **Name:** `material` (as requested, not `dms`)
- **Module:** `script` (28px tonal card, 16px input, dark surface `#10140f`, primary `#b8f3b1`)
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

Generated assets: `box.png` (520x224), `entry.png` (364x56), `bullet.png` (8x8), `lock.png` (24x24), and 320x6 `progress_box/bar.png`.
