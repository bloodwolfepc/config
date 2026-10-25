# Android environment

`nixOnDroidConfigurations.phone` is the reproducible command-line environment for the Android phone. Android applications remain outside Nix; Droid-ify favourites provide the human recovery list and `repositories.txt` records the non-default repository trust root.

The standalone `droid/flake.nix` deliberately has only public inputs, so a blank phone can bootstrap without credentials for the root flake's private infrastructure inputs. Use `github:bloodwolfepc/config?dir=droid#phone` for the initial switch and `~/src/config/droid#phone` after cloning the repository.

## Recovery boundary

| State | Source of truth |
|-------|-----------------|
| Shell packages and configuration | This flake |
| Source code | GitHub or Forgejo |
| Passwords | Vaultwarden |
| Calendar, contacts, and tasks | DAVx5 and Nextcloud |
| Files and photos | Nextcloud |
| TOTP seeds | Encrypted Aegis export in Nextcloud |
| Android application memory | Droid-ify favourites backup in Nextcloud |
| Phone SSH private key | The phone; regenerate after loss |

Do not copy another host's private SSH key to the phone. Run `phone-enroll` on the device to generate `~/.ssh/id_ed25519_phone`, authorize its printed public key declaratively on the required hosts, and revoke it when the device is retired or lost. The helper refuses to overwrite or silently repair an incomplete keypair.

Run `phone-config-sync` for routine updates. It clones the public configuration on first use, requires fast-forward updates thereafter, and applies the pinned local Android subflake.

## Android applications

Droid-ify is the installer, updater, and recovery memory. Mark each application worth restoring as a favourite. After changing favourites or repositories, use **Settings → Backup and restore** to export both **Favourites and settings** and **Repositories** directly into the phone-backup directory in Nextcloud.

After a wipe, install Droid-ify, import both files, and reinstall the restored favourites. Droid-ify does not batch-install the list on stock Android, so Android still requires approval for each installation. Applications installed outside Droid-ify are remembered only if they are also available and marked as favourites there.

There is intentionally no Git-maintained application manifest or custom comparison tool. The Droid-ify backup is the source of truth for application memory; Git declares only the reproducible terminal environment.

## Shell and terminal navigation

Interactive shells use Zsh with the shared Starship prompt, zoxide's `z` command, and the shared Zellij configuration. A top-level Nix-on-Droid shell automatically attaches or creates the local `phone` Zellij session; panes opened inside it do not recurse.

Use `Ctrl+B` as the mobile-safe prefix. `Ctrl+B [` enters scroll mode, `Ctrl+B d` detaches, `Ctrl+B h/j/k/l` moves focus, and `Ctrl+B c/n/p` creates or changes tabs. In scroll mode, use arrows or `j/k`, Page Up/Down or `b/f`, `u/d` for half pages, `g/G` for top/bottom, and `i` or Escape to return.

Detach the local session before running `angel-zellij` for the simplest remote experience. If Angel's Zellij is nested inside the local session, double the prefix: `Ctrl+B Ctrl+B d` sends `Ctrl+B d` to Angel.

## Remote development

The declared `angel` SSH host uses Angel's current Headscale address and pins its ED25519 host key. `angel-zellij` attaches to, or creates, Angel's `rainbow_session` over SSH; `angel-mosh-zellij` does the same over Mosh for unreliable mobile links.

The declared `admin-vm` host reaches the development VM through the pinned `navi` SSH jump host because admin-vm's old tailnet node is offline. Both hops enforce pinned ED25519 host keys.

The Headscale addresses are stable while the current node registrations exist. Update both the SSH configuration and documentation after intentionally re-enrolling Angel.

Nix-on-Droid has no service manager. Treat local daemons and background jobs as opportunistic; Android may stop them. Authoritative work belongs on Angel or `admin-vm`, with repositories pushed to GitHub or Forgejo.
