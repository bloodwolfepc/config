#nmcli device wifi scan
#nmcli device wifi connect X password Y

WORK=--experimental-features "nix-command flakes"
git clone <flake> /tmp

sudo nix "$WORK"\
run github:nix-community/disko -- \
--mode disko "$1" \
--arg device "$2"
#1 = location of disko configuration (/tmp/flake/hosts/modules/option/disc/impermanence-btrfs.nix)
#2 = name of /dev/sdx

sudo nixos-generate-config \
--no-filesystems --root /mnt

sudo cp /tmp/flake /etc/nixos #(~/Projects/flake)


#KEYS
#nix run nixpkgs#ssh-to-age -- -private-key -i /etc/ssh/ssh_host_ed25519_key > ~/.config/sops/age/keys.txt
#
#cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age
#
#PERSIST
#sudo chown -R $(id -u):$(id -g) /persist/home/bloodwolfe
#
#SWITCH TO SOPS USER PASSWORD