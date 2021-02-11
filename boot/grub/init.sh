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
#cat --set=modlist ${prefix}/insmod.lst;
#for module in ${modlist};
#do
#  insmod ${module};
#done;
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
#efiload $prefix/ntfs_x64.efi;

#iso
if [ -f "($ipxevd)/mapisort" ];
then
 echo mapiso --rt......;
  map -f -rt ($ipxevd)/boot.iso;
  boot  
fi;

if [ -f "($ipxevd)/mapisomemrt" ];
then
 echo mapisomem --rt....;
   map --mem -f --rt ($ipxevd)/boot.iso
   boot  
fi;	

if [ -f "($ipxevd)/mapiso" ];
then
 echo mapiso......;
  map -f -g ($ipxevd)/boot.iso;
  boot  
fi;

if [ -f "($ipxevd)/mapisomem" ];
then
 echo mapisomem....;
   map --mem -f -g ($ipxevd)/boot.iso
   boot  
fi;	

#vhd
if [ -f "($ipxevd)/mapvhd" ];
then
    map --type=hd ($ipxevd)/boot.vhd;
	boot  
fi;	
if [ -f "($ipxevd)/mapvhdmem" ];
then
    map --mem --type=hd ($ipxevd)/boot.vhd;	
	boot  
	
fi;
if [ -f "($ipxevd)/mapisomem" ];
then
 echo mapisomem....;
   map --mem -f --rt ($ipxevd)/boot.iso
   boot  
fi;	

#vhd
if [ -f "($ipxevd)/mapvhd" ];
then
    map --type=hd ($ipxevd)/boot.vhd;
	boot  
fi;	
if [ -f "($ipxevd)/mapvhdmem" ];
then
    map --mem --type=hd ($ipxevd)/boot.vhd;	
	boot  
	
fi;

#xz
if [ -f "($ipxevd)/mapxz" ];
then
    map --type=hd ($ipxevd)/boot.xz;	
	boot  
fi;
if [ -f "($ipxevd)/mapxzmem" ];
then
    map --mem --type=hd ($ipxevd)/boot.xz;	
	boot  
fi;


#ramos
if [ -f "($ipxevd)/mapramos" ];
then
   map --type=hd ($ipxevd)/boot.ramos;	
   boot  
fi;
if [ -f "($ipxevd)/mapramosmem" ];
then
   map --mem --type=hd ($ipxevd)/boot.ramos;
boot     
fi;

#ctos
if [ -f "($ipxevd)/ctos" ];
then
   configfile ($ipxevd)/ctos.sh;	
boot   
fi;
#run模块
echo "cmdline: ${grub_cmdline}";
#UEFI LoadOptions
getargs --value "file" run_file;
getargs --key "mem" run_mem;
getargs --key "rt" run_rt;
echo "file: ${run_file}";
echo "mem: ${run_mem}"
echo "rt: ${run_rt}"

if [ "${run_mem}" = "1" ];
then
  set run_mem="--mem";
else
  set run_mem="";
fi;

if [ "${run_rt}" = "1" ];
then
  set run_rt="--rt";
else
  set run_rt="";
fi;


regexp --set=1:run_ext '^.*\.(.*$)' "${run_file}";
echo "type: ${run_ext}";
if regexp '^[eE][fF][iI]$' "${run_ext}";
then
  chainloader -b "${run_file}";
elif regexp '^[iI][mM][aAgG]$' "${run_ext}";
then
  map ${run_mem} "${run_file}";
  
elif regexp '^[iI][sS][oO]$' "${run_ext}";
then
  map ${run_mem} ${run_rt} "${run_file}";
elif regexp '^[xX][zZ]$' "${run_ext}";
then
   map ${run_mem} ${run_rt} --type=hd "${run_file}";
elif regexp '^[vV][hH][dD][xX]$' "${run_ext}";
then
  ntboot --gui \
         --efi=${prefix}/ms/bootmgfw.efi \
          "${run_file}";
elif regexp '^[wW][iI][mM]$' "${run_ext}";
then
  wimboot --gui \
          @:bootmgfw.efi:${prefix}/ms/bootmgfw.efi \
          @:boot.wim:"${run_file}";
else
  echo "ERROR: Unsupported file";

fi;
#run模块结束

boot;


