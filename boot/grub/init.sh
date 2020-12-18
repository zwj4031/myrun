# Grub2-FileManager
# Copyright (C) 2016,2017,2018,2019,2020  A1ive.
#
# Grub2-FileManager is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Grub2-FileManager is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Grub2-FileManager.  If not, see <http://www.gnu.org/licenses/>.

set pager=0;
cat --set=modlist ${prefix}/insmod.lst;
for module in ${modlist};
do
  insmod ${module};
done;
export enable_progress_indicator=0;
export grub_secureboot="Not available";
if [ "${grub_platform}" = "efi" ];
then
  search -s -f -q /efi/microsoft/boot/bootmgfw.efi;
  if [ "${grub_cpu}" = "i386" ];
  then
    set EFI_ARCH="ia32";
  elif [ "${grub_cpu}" = "arm64" ];
  then
    set EFI_ARCH="aa64";
  else
    set EFI_ARCH="x64";
  fi;
  source ${prefix}/pxeinit.sh;
  net_detect;
fi
search --no-floppy --fs-uuid --set=ipxevd f00d-f00d;


if [ -f "($ipxevd)/mapiso" ];
then
  map /boot.iso;
fi;
if [ -f "($ipxevd)/mapisomem" ];
then
  getkey;
    map --mem /boot.iso
fi;	

if [ -f "($ipxevd)/mapvhd" ];
then

    map --type=hd /boot.vhd;
fi;	
if [ -f "($ipxevd)/mapvhdmem" ];
then
    map --mem --type=hd /boot.vhd;	
	
fi;
if [ -f "($ipxevd)/mapxz" ];
then
    map --type=hd /boot.xz;	
fi;
if [ -f "($ipxevd)/mapxzmem" ];
then
   map --mem --type=hd /boot.xz;	
 fi;
boot;

