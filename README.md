# Plymouth Material You theme for OSA

Material You Plymouth theme for OSA. It provides a dark Material palette, a
rounded unlock card, password bullets, and a compact progress bar. The current
release restores the last known-good Plymouth Script implementation.

- **Name:** `material` (as requested, not `dms`)
- **Module:** `script` (rounded dialog, 320x48 input, dark surface `#16130b`, primary `#e5c36c`)
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

Generated assets: `box.png` (480x280), `entry.png` (320x48), `bullet.png` (14x14), `lock.png` (24x24), and 320x4 `progress_box/bar.png`.
