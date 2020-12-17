#!/usr/bin/env sh
if [ -d "build" ]
then
    rm -rf build
fi
mkdir build

cp -r boot build/

echo "x86_64-efi"
cd build
find ./boot | cpio -o -H newc > ./memdisk.cpio
cd ..
modules=$(cat arch/x64/builtin.txt)
grub-mkimage -m ./build/memdisk.cpio -d ./grub/x86_64-efi -p "(memdisk)/boot/grub" -c arch/x64/config.cfg -o grub2toy.efi -O x86_64-efi $modules
rm -rf build
