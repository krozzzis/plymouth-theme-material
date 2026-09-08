# Plymouth Material You theme for OSA

Material You Plymouth theme for OSA. It provides a dark Material palette, a
tonal unlock card, clipped password bullets, and a compact progress bar that
appears only after the password agent has completed.

- **Name:** `material` (as requested, not `dms`)
- **Module:** `script` (16px tonal card and input, dark surface `#16130b`, primary `#e5c36c`)
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

Generated assets: `box.png` (480x200), `entry.png` (320x48), `bullet.png` (8x8), `lock.png` (20x20), and 320x4 `progress_box/bar.png`.
