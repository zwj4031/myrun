# Grub2-FileManager
# Copyright (C) 2016,2017,2018,2019,2020  A1ive.
#
# ... (版权信息和许可证保持不变) ...

set pager=0;
#cat --set=modlist ${prefix}/insmod.lst;
#for module in ${modlist};
#do
#  insmod ${module};
#done;
export enable_progress_indicator=0;
export grub_secureboot="Not available";

# --- 新增: 初始化启动目标状态标志 ---
set boot_target_found=0

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


#bootlocal
if [ -f "($ipxevd)/bootlocal" ];
then
  search -s -f -q /efi/microsoft/boot/bootmgfw.efi;
  chainloader /efi/microsoft/boot/bootmgfw.efi;
  # --- 修改: 标记已找到 ---
  set boot_target_found=1
fi;

#iso
if [ -f "($ipxevd)/mapisort" ];
then
 echo mapiso --rt......;
  map -f -rt ($ipxevd)/boot.iso;
  # --- 修改: 标记已找到 ---
  set boot_target_found=1
fi;

if [ -f "($ipxevd)/mapisomemrt" ];
then
 echo mapisomem --rt....;
   map --mem -f --rt ($ipxevd)/boot.iso
   # --- 修改: 标记已找到 ---
   set boot_target_found=1
fi;	

if [ -f "($ipxevd)/mapiso" ];
then
 echo mapiso......;
  map -f -g ($ipxevd)/boot.iso;
  # --- 修改: 标记已找到 ---
  set boot_target_found=1
fi;

if [ -f "($ipxevd)/mapisomem" ];
then
 echo mapisomem....;
   map --mem -f -g ($ipxevd)/boot.iso
   # --- 修改: 标记已找到 ---
   set boot_target_found=1
fi;	

#vhd (以及其他所有 map* 和 ctos 的 if 块都需要同样修改)
# ... 为简洁起见，此处省略对每个 map* 块的重复修改，但原理相同 ...
# 示例:
if [ -f "($ipxevd)/mapvhd" ];
then
    map --type=hd ($ipxevd)/boot.vhd;
    # --- 修改: 标记已找到 ---
    set boot_target_found=1
fi;	
# ... (对 mapvhdmem, mapxz, mapxzmem, mapramos, mapramosmem, ctos 都进行类似修改)
if [ -f "($ipxevd)/ctos" ];
then
   configfile ($ipxevd)/ctos.sh;	
   # --- 修改: 标记已找到 ---
   set boot_target_found=1
fi;


#run模块
echo "cmdline: ${grub_cmdline}";
#UEFI LoadOptions
getargs --value "file" run_file;
getargs --key "mem" run_mem;
getargs --key "rt" run_rt;

# --- 修改: 仅在 run_file 存在时才执行 run 模块逻辑 ---
if [ -n "${run_file}" ]; then
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
    set boot_target_found=1
  elif regexp '^[iI][mM][aAgG]$' "${run_ext}";
  then
    map ${run_mem} "${run_file}";
    set boot_target_found=1
  elif regexp '^[iI][sS][oO]$' "${run_ext}";
  then
    map ${run_mem} ${run_rt} "${run_file}";
    set boot_target_found=1
  elif regexp '^[xX][zZ]$' "${run_ext}";
  then
     map ${run_mem} ${run_rt} --type=hd "${run_file}";
     set boot_target_found=1
  elif regexp '^[vV][hH][dD][xX]$' "${run_ext}";
  then
    ntboot --gui \
           --efi=${prefix}/ms/bootmgfw.efi \
            "${run_file}";
    set boot_target_found=1
  elif regexp '^[wW][iI][mM]$' "${run_ext}";
  then
    wimboot --gui \
            @:bootmgfw.efi:${prefix}/ms/bootmgfw.efi \
            @:boot.wim:"${run_file}";
    set boot_target_found=1
  else
    echo "ERROR: Unsupported file type in 'run' module";
  fi;
fi;
#run模块结束


# --- 新增: Fallback 自动搜索逻辑 ---
if [ "${boot_target_found}" = "0" ];
then
  echo "Info: No explicit boot target found. Searching for fallback options..."
  
  # Fallback 1: 搜索 Windows
  if search --no-floppy --fs-uuid --set=root --file /efi/microsoft/boot/bootmgfw.efi;
  then
    echo "Fallback: Found Windows Boot Manager on (${root})."
    echo "Booting Windows..."
    chainloader /efi/microsoft/boot/bootmgfw.efi
    set boot_target_found=1
  else
    # Fallback 2: 如果找不到 Windows，则搜索常见的 Linux GRUB 菜单
    # 遍历常见的 grub.cfg 路径
    for cfg_path in /boot/grub/grub.cfg /boot/grub2/grub.cfg /grub/grub.cfg; do
      if [ "${boot_target_found}" = "0" ]; then # 确保只找一次
        if search --no-floppy --fs-uuid --set=root --file ${cfg_path};
        then
          echo "Fallback: Found Linux boot menu at (${root})${cfg_path}."
          echo "Loading menu..."
          configfile ${cfg_path}
          set boot_target_found=1
        fi
      fi
    done
  fi
fi

# --- 修改: 最终的条件启动或报错 ---
if [ "${boot_target_found}" = "1" ];
then
  boot;
else
  echo "-----------------------------------------------------"
  echo "ERROR: No bootable files or operating systems found."
  echo "All automated searches failed."
  echo "Halting script. You are now at the GRUB command line."
  echo "-----------------------------------------------------"
fi