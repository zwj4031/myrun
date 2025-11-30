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

# --- 初始化状态标志 ---
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


# --- [原始代码块] ---
# 与上一版相同，每个成功的if块内都设置了 boot_target_found=1
#bootlocal
if [ -f "($ipxevd)/bootlocal" ];
then
  search -s -f -q /efi/microsoft/boot/bootmgfw.efi;
  chainloader /efi/microsoft/boot/bootmgfw.efi;
  set boot_target_found=1
fi;

#iso, vhd, xz, ramos, ctos...
if [ -f "($ipxevd)/mapiso" ];
then
  map -f -g ($ipxevd)/boot.iso;
  set boot_target_found=1
fi;
# ... (所有其他的 map* 和 ctos 块都类似地设置 boot_target_found=1) ...
if [ -f "($ipxevd)/ctos" ];
then
   configfile ($ipxevd)/ctos.sh;	
   set boot_target_found=1
fi;

#run模块
getargs --value "file" run_file;
if [ -n "${run_file}" ]; then
  # ... (完整的 run 模块逻辑, 内部在成功时设置 boot_target_found=1) ...
  # (此处省略 run 模块的详细代码，与上一版完全相同)
  getargs --key "mem" run_mem;
  getargs --key "rt" run_rt;
  if [ "${run_mem}" = "1" ]; then set run_mem="--mem"; else set run_mem=""; fi;
  if [ "${run_rt}" = "1" ]; then set run_rt="--rt"; else set run_rt=""; fi;
  regexp --set=1:run_ext '^.*\.(.*$)' "${run_file}";
  if regexp '^[eE][fF][iI]$' "${run_ext}"; then chainloader -b "${run_file}"; set boot_target_found=1;
  elif regexp '^[iI][sS][oO]$' "${run_ext}"; then map ${run_mem} ${run_rt} "${run_file}"; set boot_target_found=1;
  # ... (其他文件类型) ...
  else echo "ERROR: Unsupported file type in 'run' module"; fi;
fi;
#run模块结束


# --- [核心逻辑部分] ---

# 仅当所有原始方法都失败时，才执行 fallback 逻辑
if [ "${boot_target_found}" = "0" ];
then
  # 定义 fallback 变量来存储搜索结果
  set fallback_os_type=""
  set fallback_root_device=""
  set fallback_chainload_path=""
  set fallback_config_file=""

  echo "Info: No explicit boot target found. Searching for fallback options..."
  
  # Fallback 1: 搜索 Windows
  
  if search --set=user -f -q /efi/microsoft/boot/bootmgfw.efi;
  then
    echo "Fallback: Found Windows Boot Manager on (${user})."
    set fallback_os_type="windows"
    set fallback_root_device="${user}"
    set fallback_chainload_path="/efi/microsoft/boot/bootmgfw.efi"
  else
    # Fallback 2: 搜索常见的 Linux GRUB 启动文件
    for boot_path in /efi/centos/grubx64.efi /boot/efi/ubuntu/grubx64.efi /efi/ubuntu/grubx64.efi /boot/efi/debian/grubx64.efi /EFI/debian/grubx64.efi /boot/EFI/debian/shimx64.efi /EFI/debian/shimx64.efi; do
      if search --set=user -f -q  ${boot_path};
      then
        echo "Fallback: Found Linux boot menu at (${user})${boot_path}."
        set fallback_os_type="linux"
        set fallback_root_device="${user}"
        set fallback_boot_file="${boot_path}"
        break
      fi
    done
  fi

  # 根据搜索结果生成并显示菜单
  if [ -n "${fallback_os_type}" ]; then
    # 找到了系统，生成带倒计时的启动菜单
    set timeout=3
    set default=0

    if [ "${fallback_os_type}" = "windows" ]; then
      menuentry "Boot Windows (found on ${fallback_root_device})" {
        echo "Starting Windows in 3 seconds..."
        set root=${fallback_root_device}
        chainloader ${fallback_chainload_path}
      }
    fi
    
    if [ "${fallback_os_type}" = "linux" ]; then
      menuentry "Load Linux Menu (found at ${fallback_root_device}${fallback_boot_file})" {
        echo "Loading Linux menu in 3 seconds..."
        set root=${fallback_root_device}
        chainloader ${fallback_boot_file}
      }
    fi

  else
    # --- [核心修改] ---
    # 如果 fallback 搜索也失败了，则生成一个最终的 "失败" 菜单
    set timeout=-1 # -1 表示无限等待，不自动选择
    set default=0
    
    echo "-----------------------------------------------------"
    echo "ERROR: No bootable files or operating systems found."
    echo "All automated searches failed."
    echo "Please choose an option from the menu below."
    echo "-----------------------------------------------------"
    
    menuentry "Enter GRUB Command Line 20251130" {
        # 这个菜单项是信息性的。GRUB菜单本身支持按'c'进入命令行。
        echo "To enter the command line, please press the 'c' key on your keyboard."
        echo "To return to this menu, press the ESC key."
    }
    
    menuentry "Reboot Computer" {
        echo "Rebooting..."
        reboot
    }
    
    menuentry "Shutdown Computer" {
        echo "Shutting down..."
        halt
    }
  fi

# 如果原始方法成功了，我们才需要boot命令
elif [ "${boot_target_found}" = "1" ];
then
  boot;
fi