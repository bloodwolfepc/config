# main-vps

Portable mail edge and disaster-recovery host. It assumes an x86-64 KVM VPS with
one persistent disk and DHCPv4, but has no OVH API or address dependencies.

## Provider inputs

Before installation, change only `provider.nix`:

- `installDisk`: stable `/dev/disk/by-id/...` path observed in rescue mode.
- `uplinkMatch`: systemd-networkd interface glob, normally `en* eth*`.
- `bootstrapPublicSsh`: leave `true` only until tailnet SSH is verified.

The disk layout supports BIOS and UEFI boot and includes AHCI, NVMe, Virtio block,
Virtio SCSI, and XHCI drivers. Moving providers therefore means reinstalling from
this flake, restoring `/srv/dr` from independent backup, enrolling Tailscale and
WireGuard, and changing DNS/PTR—not converting the old provider's disk image.

A provider without DHCPv4 needs a small `systemd.network.networks."10-uplink"`
override for its assigned address, gateway, and DNS. Keep that override separate
from mail and recovery configuration.

## SSH trust

Home Manager pins main-vps in `home-manager/bloodwolfe/modules/security/main-vps.known_hosts`.
The `main-vps`, `main-vps.srvctl.ts.net`, and `mx.tinywolfe.net` SSH aliases all use
its tailnet address and strict checking, separately from srv-vm and Navi. Client
authentication uses Angel's SOPS-managed `~/.ssh/id_ed25519`, matching the declared
`nixos/modules/users/bloodwolfe/id_angel.pub` authorization—not the separate
`id_ed25519_sk_angel` hardware key used for Git signing/pushing.

The ED25519 public key was authenticated on 2026-11-02 by converting it with
`ssh-to-age` and matching the existing `main-vps-system` recipient in the secrets
repository's `.sops.yaml`: `age14s0gxsfvjwl77fd0re203ru05rrau3kj5we4lgqkgtravk5ca3wqpdtpnj`.
No private key or decrypted secret is needed. The `ssh-host-trust` check tests the
generated aliases and this binding across Angel, Angelstuck, and Navi. A newly
presented key alone is never authority to replace the pin; reinstallation/rotation
must re-enroll both SOPS identity and SSH trust through an authenticated channel.

## Install order

1. Boot provider rescue media and record the stable disk path, interface name,
   IPv4, gateway behavior, and SSH host key shown by rescue.
2. Set `provider.nix`; evaluate the flake and inspect Disko's destructive target.
3. Point `mx.tinywolfe.net` at the assigned IPv4 so ACME can validate without
   changing the domain MX yet.
4. Run `nixos-anywhere` from Angel against `.#main-vps`.
5. Each host generates its persistent WireGuard private key on first activation.
   Set `homePublicKey` in `wireguard.nix` and `vpsWireGuardPublicKey` in `srv`'s
   `modules/service-vm.nix` from the resulting public keys; private keys never
   leave their hosts.
6. Enroll the Tailscale client with `https://ts.tinywolfe.net`, verify Headscale
   SSH and the WireGuard link across a reboot, then set
   `bootstrapPublicSsh = false` and deploy again. Enroll the installed persistent
   SSH host key in both SOPS and the Home Manager pin above, not the rescue key;
   run `ssh-host-trust` before considering host enrollment complete.
7. Test Postfix recipient rejection, queue persistence, Rspamd, and delivery to
   Stalwart before changing MX. Set PTR to `mx.tinywolfe.net`.
8. Configure Object-Locked off-site backups and complete a disposable restore
   before enabling any disaster-recovery service.

`provider.nix` deliberately contains an invalid disk path until purchase-time
inspection. Do not replace it with `/dev/vda` or another unstable kernel name.
