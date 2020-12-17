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
set debug=off;
set color_normal=white/black;
set color_highlight=black/white;
source $prefix/search.sh;
version;
echo "cmdline: ${grub_cmdline}";

#UEFI LoadOptions
getargs --value "file" run_file;
getargs --key "mem" run_mem;
echo "file: ${run_file}";
echo "mem: ${run_mem}"
if [ "${run_mem}" = "1" ];
then
  set run_mem="--mem";
else
  set run_mem="";
fi;
getkey;

#function installwin {
#  set installiso=string.gsub ($2, "/", "\\\\");
#  save_env -f ${prefix}/install/envblk installiso;
#  cat ${prefix}/install/envblk;
#  wimboot @:bootmgfw.efi:${prefix}/ms/bootmgfw.efi \
#          @:bcd:${prefix}/ms/bcd \
#          @:boot.sdi:${prefix}/ms/boot.sdi \
#          @:null.cfg:${prefix}/install/envblk \
#          @:mount.exe:${prefix}/install/mount.exe \
#          @:start.bat:${prefix}/install/start.bat \
#          @:winpeshl.ini:${prefix}/install/winpeshl.ini \
#          @:boot.wim:"${1}";
#}

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
# loopback loop "${run_file}";
# set win_prefix=(loop)/sources/install;
# set win64_prefix=(loop)/x64/sources/install;
# if [ -f ${win_prefix}.wim -o -f ${win_prefix}.esd -o -f ${win_prefix}.swm ];
# then
#   installwin "(loop)/sources/boot.wim" "${run_file}";
# elif [ -f ${win64_prefix}.wim -o -f ${win64_prefix}.esd -o -f ${win64_prefix}.swm ];
# then
#   installwin "(loop)/x64/sources/boot.wim" "${run_file}";
# fi;
  map ${run_mem} "${run_file}";
elif regexp '^[vV][hH][dD]$' "${run_ext}";
then
  ntboot --gui \
         --efi=${prefix}/ms/bootmgfw.efi \
         --sdi=${prefix}/ms/boot.sdi \
         "${run_file}";
elif regexp '^[vV][hH][dD][xX]$' "${run_ext}";
then
  ntboot --gui \
         --efi=${prefix}/ms/bootmgfw.efi \
         --sdi=${prefix}/ms/boot.sdi \
         "${run_file}";
elif regexp '^[wW][iI][mM]$' "${run_ext}";
then
  wimboot --gui \
          @:bootmgfw.efi:${prefix}/ms/bootmgfw.efi \
          @:bcd:${prefix}/ms/bcd \
          @:boot.sdi:${prefix}/ms/boot.sdi \
          @:boot.wim:"${run_file}";
else
  echo "ERROR: Unsupported file";
  exit;
fi;
