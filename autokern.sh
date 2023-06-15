#!/bin/bash


#downloads kernel
read -p "Kernel URL or Filepath to Uncompressed Kernel: " kernURL
kernFile=$(basename $kernURL .tar.xz)


if [ ! -d "$kernFile" ]; then
	echo "dont exist"
	wget $kernURL
	if [ $? != 0 ]; then
		echo "URL Not found or Not entered ocrrectly" >&2
		exit 1
	fi
	
	unxz "$kernFile.tar.xz"
	tar -xvf "$kernFile.tar"
	rm "$kernFile.tar" #removing unwanted files

fi

#preparing kernel

cd $kernFile
make mrproper

#preparing kernel config
#copy old config
zcat /proc/config.gz > .config
#set defaults for new options
make olddefconfig
#only kernel modules are ones actively put in a list by modprobed. delete next line if you dont have this set up
make LSMOD=$HOME/.config/modprobed.db localmodconfig
#allows for further graphical configuration
make menuconfig

#compiling
make -j$(($(nproc) -1))

#modules
make modules
sudo make modules_install
sudo cp -v arch/x86/boot/bzImage /boot/vmlinuz-$kernFile

#bootloader
#will need to change --disk flag, and parts of the unicode flag such as root partition and file system type to work
sudo efibootmgr --create --disk /dev/sda --part 1 --label "Arch Linux" --loader /vmlinuz-$kernFile --unicode "noinitrd root=/dev/sda2 rw rootfstype=ext4 nomodeset quiet"
#extra stuff for nvidia users. If you do not have a Nvidia card, you can delete this
sudo pacman -S nvidia-dkms

