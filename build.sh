#!/bin/bash
rhel_ver=${1:-7.4}
echo "Building Virtual Machine using virt-install for ${rhel_ver}"

ks_file="rhel-${rhel_ver}-ci-cloud_edit.ks"
disk_name="rhel-vagrant-${rhel_ver}.x86_64.qcow2"
box_name="rhel-${rhel_ver}.x86_64.box"
vm_name="rhel-vm-${rhel_ver}.x86_64.box"
temp_dir="`pwd`/tmp"

tree=http://download.eng.bos.redhat.com/composes/released/RHEL-7/${rhel_ver}/Server/x86_64/os/

if [ ! -f ${ks_file} ]; then
    cp template_kickstart.ks ${ks_file}
fi

echo "Installing virtual machine using ${tree}\n"
virt-install --connect=qemu:///system \
    --network=bridge:virbr0 \
    --initrd-inject=./${ks_file} \
    --extra-args="ks=file:/${ks_file} no_timer_check console=tty0 console=ttyS0,115200 net.ifnames=0 biosdevname=0" \
    --name=${vm_name} \
    --disk ./${disk_name},size=20,bus=virtio \
    --ram 2048 \
    --vcpus=2 \
    --check-cpu \
    --accelerate \
    --hvm \
    --location=$tree \
    --nographics --noreboot #--debug 

echo "Compressing image"
LIBGUESTFS_BACKEND=direct virt-sparsify --compress -o compat=0.10 --tmp ${temp_dir} ${disk_name} box.img

echo "Creating box image: ${box_name}"
tar cvzf ${box_name} ./metadata.json ./Vagrantfile ./box.img
