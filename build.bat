rd /s /q build
mkdir build
xcopy boot build /s /e /y


%~dp0\bin\find.exe ./boot | %~dp0\bin\cpio.exe -o -H newc > ./build/memdisk.cpio


set /p modules= < %~dp0\arch\x64\builtin.txt

%~dp0\bin\grub-mkimage.exe -m %~dp0\build\memdisk.cpio -d %~dp0\grub\x86_64-efi -p "(memdisk)/boot/grub" -c %~dp0\arch\x64\config.cfg -o run.efi -O x86_64-efi %modules%
pause