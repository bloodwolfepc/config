DRI="amdgpu"
DRI2="snd_hda_intel"
PCI1="0000:03:00.0"
PCI2="0000:03:00.1"
ID1="1002 73ef"
ID2="1002 ab28"

echo "virsh nodedev-reattach" &&
virsh nodedev-reattach --device pci_0000_03_00_0 && 
virsh nodedev-reattach --device pci_0000_03_00_1 && 
echo "switching to amdgpu drivers for $PCI1($ID1) and $PCI2($ID2)" &&
echo "$DRI" > /sys/bus/pci/devices/$PCI1/driver_override &&
echo "$DRI2" > /sys/bus/pci/devices/$PCI2/driver_override &&
echo "$PCI1" > /sys/bus/pci/devices/$PCI1/driver/unbind &&
echo "$PCI2" > /sys/bus/pci/devices/$PCI2/driver/unbind &&
echo "$PCI1" > /sys/bus/pci/drivers/$DRI/bind &&
echo "$PCI2" > /sys/bus/pci/drivers/$DRI2/bind &&
echo "OK"
