DRI="vfio-pci"
PCI1="0000:03:00.0"
PCI2="0000:03:00.1"
ID1="1002 73ef"
ID2="1002 ab28"

echo "switching to amdgpu drivers for $PCI1($ID1) and $PCI2($ID2)" &&

#remove device and rescan
#echo 1 > /sys/bus/pci/devices/$PCI1/remove &&
#echo 1 > /sys/bus/pci/devices/$PCI2/remove &&
#echo 1 > /sys/bus/pci/rescan &&

#override
echo "$DRI" > /sys/bus/pci/devices/0000:03:00.0/driver_override &&
echo "$DRI" > /sys/bus/pci/devices/0000:03:00.1/driver_override &&

#unbind from current driver
echo "$PCI1" > /sys/bus/pci/devices/$PCI1/driver/unbind &&
echo "$PCI2" > /sys/bus/pci/devices/$PCI2/driver/unbind &&
#bind to new DRI
echo "$PCI1" > /sys/bus/pci/drivers/$DRI/bind && #echo: no such device
echo "$PCI2" > /sys/bus/pci/drivers/$DRI/bind && #this works

#prepare virsh
echo 1 > /sys/bus/pci/rescan &&
sudo virsh nodedev-detach pci_0000_03_00_0 &&
sudo virsh nodedev-detach pci_0000_03_00_1 &&
echo "virsh nodedev-detach" &&
echo "OK"







#v2

#echo "switching to vfio drivers for $PCI1($ID1) and $PCI2($ID2)"
#
##remove device
#echo 1 | sudo tee /sys/bus/pci/rescan &&
#echo 1 | sudo tee /sys/bus/pci/devices/$PCI1/remove &&
#echo 1 | sudo tee /sys/bus/pci/devices/$PCI2/remove &&
#echo 1 | sudo tee /sys/bus/pci/rescan &&
##add id to DRI
##echo "$ID1" | sudo tee /sys/bus/pci/drivers/$DRI/new_id
##echo "$ID2" | sudo tee /sys/bus/pci/drivers/$DRI/new_id
##unbind from current driver
#echo "$PCI1" | sudo tee /sys/bus/pci/devices/$PCI1/driver/unbind &&
#echo "$PCI2" | sudo tee /sys/bus/pci/devices/$PCI2/driver/unbind &&
##bind to DRI
#echo "$PCI1" | sudo tee "/sys/bus/pci/drivers/$DRI/bind" &&
#echo "$PCI2" | sudo tee "/sys/bus/pci/drivers/$DRI/bind" &&
##remove id
##echo "$ID1" | sudo tee /sys/bus/pci/drivers/$DRI/remove_id &&
##echo "$ID2" | sudo tee /sys/bus/pci/drivers/$DRI/remove_id &&
##prepare virsh
#echo 1 | sudo tee /sys/bus/pci/rescan &&
#sudo virsh nodedev-detach pci_0000_03_00_0 &&
#sudo virsh nodedev-detach pci_0000_03_00_1 &&
#echo "virsh nodedev-detach" &&
#echo "OK"


#v1
#echo "amdgpu" | sudo tee /sys/bus/pci/devices/0000:03:00.0/driver_override &&
#echo "0000:03:00.0" | sudo tee /sys/bus/pci/drivers/amdgpu/bind &&
#echo "0000:03:00.0 is bound to amdgpu" &&
#
#
#echo "0000:03:00.1" | sudo tee /sys/bus/pci/drivers/vfio-pci/unbind &&
#echo "snd_hda_intel" | sudo tee /sys/bus/pci/devices/0000:03:00.1/driver_override &&
#echo "0000:03:00.1" | sudo tee /sys/bus/pci/drivers/snd_hda_intel/bind &&
#echo "0000:03:00.1 is bound to snd_hda_intel"


#echo 1 | sudo tee /sys/class/drm/card0/device/remove
#echo "0000:03:00.0" | sudo tee /sys/bus/pci/drivers/amdgpu/unbind && #crashes hyprland
#
#echo "vfio-pci" | sudo tee /sys/bus/pci/devices/0000:03:00.0/driver_override &&
#echo "0000:03:00.0" | sudo tee /sys/bus/pci/drivers/vfio-pci/bind &&
#echo "0000:03:00.0 is bound to vfio-pci" &&
#
#echo "0000:03:00.1" | sudo tee /sys/bus/pci/drivers/amdgpu/unbind &&
#echo "vfio-pci" | sudo tee /sys/bus/pci/devices/0000:03:00.1/driver_override &&
#echo "0000:03:00.1" | sudo tee /sys/bus/pci/drivers/vfio-pci/bind &&
#echo "0000:03:00.1 is bound to vfio-pci" &&
