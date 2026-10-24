# Android environment

`nixOnDroidConfigurations.phone` is the reproducible command-line environment for the Android phone. Android applications remain outside Nix; `apps.txt` is their auditable recovery inventory and `repositories.txt` pins the non-default repository trust root.

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
| Android application inventory | `apps.txt` |
| Phone SSH private key | The phone; regenerate after loss |

Do not copy another host's private SSH key to the phone. Generate `~/.ssh/id_ed25519_phone` on the device, authorize its public key declaratively on the required hosts, and revoke it when the device is retired or lost.

## Remote development

The declared `angel` SSH host uses Angel's current Headscale address and pins its ED25519 host key. `angel-zellij` attaches to, or creates, Angel's `rainbow_session` over SSH; `angel-mosh-zellij` does the same over Mosh for unreliable mobile links.

The declared `admin-vm` host reaches the development VM through the pinned `navi` SSH jump host because admin-vm's old tailnet node is offline. Both hops enforce pinned ED25519 host keys.

The Headscale addresses are stable while the current node registrations exist. Update both the SSH configuration and documentation after intentionally re-enrolling Angel.

Nix-on-Droid has no service manager. Treat local daemons and background jobs as opportunistic; Android may stop them. Authoritative work belongs on Angel or `admin-vm`, with repositories pushed to GitHub or Forgejo.
