#!/usr/bin/env bash
set -euo pipefail

# Match client output as data, never evaluate the client's shell program.
# libvirt 12.7.0's default SSH transport (including virsh -r):
libvirt_command="sh -c 'which virt-ssh-helper 1>/dev/null 2>&1; if test \$? = 0; then     virt-ssh-helper 'qemu:///system'; else    if 'nc' -q 2>&1 | grep \"requires an argument\" >/dev/null 2>&1; then ARG=-q0;else ARG=;fi;'nc' \$ARG -U /var/run/libvirt/libvirt-sock; fi'"
libvirt_readonly_command="sh -c 'which virt-ssh-helper 1>/dev/null 2>&1; if test \$? = 0; then     virt-ssh-helper -r 'qemu:///system'; else    if 'nc' -q 2>&1 | grep \"requires an argument\" >/dev/null 2>&1; then ARG=-q0;else ARG=;fi;'nc' \$ARG -U /var/run/libvirt/libvirt-sock-ro; fi'"
# terraform-provider-libvirt 0.9.8: qemu+sshcmd with proxy=native.
provider_command="sh -c 'virt-ssh-helper \"qemu:///system\"'"
storage_guard='findmnt -rn --mountpoint /srv/libvirt >/dev/null && test -f /srv/libvirt/.srv-storage && test -d /data/garage && test -f /data/garage/.srv-storage'

case "${SSH_ORIGINAL_COMMAND:-}" in
  "$storage_guard")
    findmnt -rn --mountpoint /srv/libvirt >/dev/null
    test -f /srv/libvirt/.srv-storage
    test -d /data/garage
    test -f /data/garage/.srv-storage
    ;;
  "$libvirt_command" | "$provider_command")
    exec virt-ssh-helper qemu:///system
    ;;
  "$libvirt_readonly_command")
    exec virt-ssh-helper -r qemu:///system
    ;;
  *)
    echo 'Denied: operator key permits only system libvirt RPC and the exact storage guard.' >&2
    exit 126
    ;;
esac
