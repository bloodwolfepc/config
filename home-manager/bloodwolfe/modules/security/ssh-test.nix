{ pkgs, homes }:
let
  configs = map (home: home.home.file.".ssh/config".source) homes;
  pins = map (home: home.home.file.".ssh/known_hosts.d/main-vps".source) homes;
in
pkgs.runCommand "main-vps-ssh-trust-test"
  {
    nativeBuildInputs = with pkgs; [
      openssh
      ssh-to-age
    ];
  }
  ''
    for config in ${pkgs.lib.escapeShellArgs (map toString configs)}; do
      for host in main-vps main-vps.srvctl.ts.net mx.tinywolfe.net; do
        ssh -G -F "$config" "$host" > effective
        grep -Fx 'hostname main-vps.srvctl.ts.net' effective
        grep -Fx 'hostkeyalias main-vps' effective
        grep -Fx 'identitiesonly yes' effective
        grep -Fx 'identityfile /home/bloodwolfe/.ssh/id_ed25519' effective
        grep -Fx 'stricthostkeychecking true' effective
        grep -Fx 'userknownhostsfile /home/bloodwolfe/.ssh/known_hosts.d/main-vps' effective
      done
    done
    for pin in ${pkgs.lib.escapeShellArgs (map (pin: "${pin}") pins)}; do
      ssh-keygen -F main-vps -f "$pin" > found
      awk '$2 == "ssh-ed25519" {print $2, $3}' found | ssh-to-age > recipient
      # Existing host enrollment, not trust-on-first-use from a network scan.
      grep -Fx 'age14s0gxsfvjwl77fd0re203ru05rrau3kj5we4lgqkgtravk5ca3wqpdtpnj' recipient
    done
    touch "$out"
  ''
