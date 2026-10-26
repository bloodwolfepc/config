# Repository notes

## Home Manager configuration modes

Native application configuration is selected through `dotfiles.source` from
`home-manager/bloodwolfe/modules/dotfiles.nix`:

```nix
config.dotfiles.source "relative/path" ./store-backed-source
```

- `angel` sets `dotfiles.mutable = true` and links native configuration to the
  checkout at `~/src/config/home-manager/bloodwolfe/modules` for live editing.
- `angelstuck` is the immutable fallback for the same machine. It forces
  `dotfiles.mutable = false`, so configuration comes from the active Nix store
  generation and does not require a checkout.
- `navi` is immutable. New hosts are immutable by default.

Use `dotfiles.source` for native configuration files and directories that an
application reads at runtime. Keep derivation inputs, generated files, packaged
scripts, secrets, and other build-time inputs store-backed; those require a
rebuild by design. Do not add direct `$FLAKE` paths or unconditional
out-of-store links.

Validate changes against all three system profiles:

```bash
nix eval .#nixosConfigurations.angel.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.angelstuck.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.navi.config.system.build.toplevel.drvPath
```

## Mobile development

- `admin-vm`'s unprivileged `mobiledev` account is the persistent mobile development host. Work there only on topic branches; its pre-push hook rejects `master` and `main` and runs repository checks.
- Mobile commits are working history. Do not claim or simulate the operator's signature. Canonical commits are reviewed, squashed when appropriate, and YubiKey-signed on Angel.
- Never ask a mobile operator to touch hardware attached to Angel. Use a reviewable branch or defer the signed promotion instead.
- Keep credentials host-specific: the phone authenticates to admin-vm, while repository-scoped admin-vm deploy keys push topic branches.
