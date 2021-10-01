#!/bin/bash

echo "Lichee pi Zero (V3S)"
echo "Welcome to use lichee pi nano sdk"
toolchain_dir="toolchain"
cross_compiler="arm-linux-gnueabihf"
temp_root_dir=$PWD


#uboot=========================================================
u_boot_dir="Lichee-Pi-u-boot"
u_boot_config_file=""
u_boot_boot_cmd_file=""
#uboot=========================================================

#linux opt=========================================================
linux_dir="Lichee-Pi-linux"
linux_config_file=""
#linux opt=========================================================

#linux opt=========================================================
buildroot_dir="buildroot"
buildroot_config_file=""
#linux opt=========================================================


#pull===================================================================
pull_uboot(){
	rm -rf ${temp_root_dir}/${u_boot_dir} &&\
	mkdir -p ${temp_root_dir}/${u_boot_dir} &&\
	cd ${temp_root_dir}/${u_boot_dir} &&\
	git clone -b v3s-spi-experimental https://github.com/Lichee-Pi/u-boot.git
	if [ ! -d ${temp_root_dir}/${u_boot_dir}/u-boot ]; then
		echo "Error:pull u_boot failed"
    		exit 0
	else
		mv ${temp_root_dir}/${u_boot_dir}/u-boot/* ${temp_root_dir}/${u_boot_dir}/
		rm -rf ${temp_root_dir}/${u_boot_dir}/u-boot
		echo "pull u-boot ok"
	fi
}

pull_linux(){
	rm -rf ${temp_root_dir}/${linux_dir} &&\
	mkdir -p ${temp_root_dir}/${linux_dir} &&\
	cd ${temp_root_dir}/${linux_dir} &&\
	#git clone -b zero-5.2.y https://github.com/Lichee-Pi/linux.git linux
    git clone -b zero-4.13.y https://github.com/Lichee-Pi/linux.git linux

	if [ ! -d ${temp_root_dir}/${linux_dir}/linux ]; then
		echo "Error:pull linux failed"
    		exit 0
	else
		mv ${temp_root_dir}/${linux_dir}/linux/* ${temp_root_dir}/${linux_dir}/
		rm -rf ${temp_root_dir}/${linux_dir}/linux
		echo "pull linux ok"
	fi
}

pull_toolchain(){
	rm -rf ${temp_root_dir}/${toolchain_dir}
	mkdir -p ${temp_root_dir}/${toolchain_dir}
	cd ${temp_root_dir}/${toolchain_dir}
	ldconfig
    wget https://releases.linaro.org/components/toolchain/binaries/latest-7/arm-linux-gnueabihf/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf.tar.xz &&\
    tar xvJf gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf.tar.xz
    if [ ! -d ${temp_root_dir}/${toolchain_dir}/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf ]; then
        echo "Error:pull toolchain failed"
            exit 0
    else
        echo "pull toolchain ok"
    fi
}

pull_buildroot(){
	rm -rf ${temp_root_dir}/${buildroot_dir}
	mkdir -p ${temp_root_dir}/${buildroot_dir}
	cd ${temp_root_dir}/${buildroot_dir}  &&\
	#wget https://buildroot.org/downloads/buildroot-2017.08.tar.gz && tar -xvf buildroot-2017.08.tar.gz
    git clone https://github.com/Unturned3/v3s_buildroot.git buildroot

    if [ ! -d ${temp_root_dir}/${buildroot_dir} ]; then
		echo "Error:pull buildroot failed"
    	exit 0
	else
		# mv ${temp_root_dir}/${buildroot_dir}/buildroot-2021.02.3/* ${temp_root_dir}/${buildroot_dir}/buildroot-2021.02.3
		# rm -rf ${temp_root_dir}/${buildroot_dir}/buildroot-2021.02.3
		echo "pull buildroot ok"
	fi
}

pull_all(){
    sudo apt-get update
	sudo apt-get install -y autoconf automake libtool gettext
    sudo apt-get install -y make gcc g++ swig python-dev bc python u-boot-tools bison flex bc libssl-dev libncurses5-dev unzip mtd-utils
	sudo apt-get install -y libc6-i386 lib32stdc++6 lib32z1
	sudo apt-get install -y libc6:i386 libstdc++6:i386 zlib1g:i386
	pull_uboot
	pull_linux
	pull_toolchain
	pull_buildroot
    #copy file config
	# cp -f ${temp_root_dir}/buildroot.config ${temp_root_dir}/${buildroot_dir}/buildroot-2021.02.3/
	# cp -f ${temp_root_dir}/linux-licheepi_nano_defconfig ${temp_root_dir}/${linux_dir}/arch/arm/configs/licheepi_nano_defconfig
	# cp -f ${temp_root_dir}/linux-licheepi_nano_spiflash_defconfig ${temp_root_dir}/${linux_dir}/arch/arm/configs/licheepi_nano_spiflash_defconfig
	# cp -f ${temp_root_dir}/suniv-f1c100s-licheepi-nano.dts ${temp_root_dir}/${linux_dir}/arch/arm/boot/dts/suniv-f1c100s-licheepi-nano.dts
	# cp -f ${temp_root_dir}/uboot-licheepi_nano_defconfig ${temp_root_dir}/${u_boot_dir}/configs/licheepi_nano_defconfig
	# cp -f ${temp_root_dir}/uboot-licheepi_nano_spiflash_defconfig ${temp_root_dir}/${u_boot_dir}/configs/licheepi_nano_spiflash_defconfig
	#create output folder
    mkdir -p ${temp_root_dir}/output
}
#pull===================================================================

#clean===================================================================
clean_log(){
	rm -f ${temp_root_dir}/*.log
}

clean_all(){
	clean_log
	clean_uboot
	clean_linux
	clean_buildroot
}
#clean===================================================================


#env===================================================================
update_env(){
	if [ ! -d ${temp_root_dir}/${toolchain_dir}/gcc-linaro-7.4.1-2019.02-i686_arm-linux-gnueabi ]; then
		if [ ! -d ${temp_root_dir}/${toolchain_dir}/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf ]; then
			echo "Error:toolchain no found,Please use ./buid.sh pull_all "
	    		exit 0
		else
			export PATH="$PWD/${toolchain_dir}/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf/bin":"$PATH"
		fi
	else
		export PATH="$PWD/${toolchain_dir}/gcc-linaro-7.4.1-2019.02-i686_arm-linux-gnueabi/bin":"$PATH"
	fi

}
check_env(){
	if [ ! -d ${temp_root_dir}/${toolchain_dir} ] ||\
	 [ ! -d ${temp_root_dir}/${u_boot_dir} ] ||\
	 [ ! -d ${temp_root_dir}/${buildroot_dir} ] ||\
	 [ ! -d ${temp_root_dir}/${linux_dir} ]; then
		echo "Error:env error,Please use ./buid.sh pull_all"
		exit 0
	fi
}
#env===================================================================

#uboot=========================================================

clean_uboot(){
	cd ${temp_root_dir}/${u_boot_dir}
	make ARCH=arm CROSS_COMPILE=${cross_compiler}- mrproper > /dev/null 2>&1
}


build_uboot(){
	cd ${temp_root_dir}/${u_boot_dir}
	echo "Building uboot ..."
    	echo "--->Configuring ..."
	make ARCH=arm CROSS_COMPILE=${cross_compiler}- ${u_boot_config_file} > /dev/null 2>&1
	if [ $? -ne 0 ] || [ ! -f ${temp_root_dir}/${u_boot_dir}/.config ]; then
		echo "Error: .config file not exist"
		exit 1
	fi
	echo "--->Get cpu info ..."
	proc_processor=$(grep 'processor' /proc/cpuinfo | sort -u | wc -l)
	echo "--->Compiling ..."
  	make ARCH=arm CROSS_COMPILE=${cross_compiler}- -j${proc_processor} > ${temp_root_dir}/build_uboot.log 2>&1

	if [ $? -ne 0 ] || [ ! -f ${temp_root_dir}/${u_boot_dir}/u-boot ]; then
        	echo "Error: UBOOT NOT BUILD.Please Get Some Error From build_uboot.log"
		error_msg=$(cat ${temp_root_dir}/build_uboot.log)
		if [[ $(echo $error_msg | grep "ImportError: No module named _libfdt") != "" ]];then
		    echo "Please use Python2.7 as default python interpreter"
		fi
        	exit 1
	fi

	if [ ! -f ${temp_root_dir}/${u_boot_dir}/u-boot-sunxi-with-spl.bin ]; then
        	echo "Error: UBOOT NOT BUILD.Please Enable spl option"
        	exit 1
	fi
	#make boot.src
	if [ -n "$u_boot_boot_cmd_file" ];then
		mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "Beagleboard boot script" -d ${temp_root_dir}/${u_boot_boot_cmd_file} ${temp_root_dir}/output/boot.scr
	fi
	echo "Build uboot ok"
}
#uboot=========================================================

#linux=========================================================
clean_linux(){
	cd ${temp_root_dir}/${linux_dir}
	make ARCH=arm CROSS_COMPILE=${cross_compiler}- mrproper > /dev/null 2>&1
}

build_linux(){
	cd ${temp_root_dir}/${linux_dir}
	echo "Building linux ..."
    	echo "--->Configuring ..."
	make ARCH=arm CROSS_COMPILE=${cross_compiler}- ${linux_config_file} > /dev/null 2>&1
	if [ $? -ne 0 ] || [ ! -f ${temp_root_dir}/${linux_dir}/.config ]; then
		echo "Error: .config file not exist"
		exit 1
	fi
	echo "--->Get cpu info ..."
	proc_processor=$(grep 'processor' /proc/cpuinfo | sort -u | wc -l)
	echo "--->Compiling ..."
  	make ARCH=arm CROSS_COMPILE=${cross_compiler}- -j${proc_processor} > ${temp_root_dir}/build_linux.log 2>&1

	if [ $? -ne 0 ] || [ ! -f ${temp_root_dir}/${linux_dir}/arch/arm/boot/zImage ]; then
        	echo "Error: LINUX NOT BUILD.Please Get Some Error From build_linux.log"
			#error_msg=$(cat ${temp_root_dir}/build_linux.log)
			#if [[ $(echo $error_msg | grep "ImportError: No module named _libfdt") != "" ]];then
			#    echo "Please use Python2.7 as default python interpreter"
			#fi
        	exit 1
	fi

	if [ ! -f ${temp_root_dir}/${linux_dir}/arch/arm/boot/dts/sun8i-v3s-licheepi-zero.dtb ]; then
        	echo "Error: UBOOT NOT BUILD.${temp_root_dir}/${linux_dir}/arch/arm/boot/dts/sun8i-v3s-licheepi-zero.dtb not found"
        	exit 1
	fi

	#build linux kernel modules
	make ARCH=arm CROSS_COMPILE=${cross_compiler}- -j${proc_processor} INSTALL_MOD_PATH=${temp_root_dir}/${linux_dir}/out modules > /dev/null 2>&1
	make ARCH=arm CROSS_COMPILE=${cross_compiler}- -j${proc_processor} INSTALL_MOD_PATH=${temp_root_dir}/${linux_dir}/out modules_install > /dev/null 2>&1

	echo "Build linux ok"
}
#linux=========================================================

#buildroot=========================================================

clean_buildroot(){
	cd ${temp_root_dir}/${buildroot_dir}
	make ARCH=arm CROSS_COMPILE=${cross_compiler}- clean > /dev/null 2>&1
}


build_buildroot(){
	cd ${temp_root_dir}/${buildroot_dir}/${buildroot_dir}
	echo "Building buildroot ..."
    	echo "--->Configuring ..."
	rm ${temp_root_dir}/${buildroot_dir}/${buildroot_dir}/.config
	make ${buildroot_config_file}
	if [ $? -ne 0 ] || [ ! -f ${temp_root_dir}/${buildroot_dir}/${buildroot_dir}/.config ]; then
		echo "Error: .config file not exist"
		exit 1
	fi

    echo "--->Get cpu info ..."
    proc_processor=$(grep 'processor' /proc/cpuinfo | sort -u | wc -l)
	echo "--->Compiling ..."
  	make -j${proc_processor} > ${temp_root_dir}/build_buildroot.log 2>&1

	if [ $? -ne 0 ] || [ ! -d ${temp_root_dir}/${buildroot_dir}/${buildroot_dir}/output/target ]; then
        	echo "Error: BUILDROOT NOT BUILD.Please Get Some Error From build_buildroot.log"
        	exit 1
	fi
	echo "Build buildroot ok"
}
#buildroot=========================================================

#copy=========================================================
copy_uboot(){
	cp ${temp_root_dir}/${u_boot_dir}/u-boot-sunxi-with-spl.bin ${temp_root_dir}/output/
}
copy_linux(){
	cp ${temp_root_dir}/${linux_dir}/arch/arm/boot/zImage ${temp_root_dir}/output/
	cp ${temp_root_dir}/${linux_dir}/arch/arm/boot/dts/sun8i-v3s-licheepi-zero.dtb ${temp_root_dir}/output/
	mkdir -p ${temp_root_dir}/output/modules/
	cp -rf ${temp_root_dir}/${linux_dir}/out/lib ${temp_root_dir}/output/modules/
}
copy_buildroot(){
	cp -r ${temp_root_dir}/${buildroot_dir}/${buildroot_dir}/output/target ${temp_root_dir}/output/rootfs/
	cp ${temp_root_dir}/${buildroot_dir}/${buildroot_dir}/output/images/rootfs.tar ${temp_root_dir}/output/
	gzip -c ${temp_root_dir}/output/rootfs.tar > ${temp_root_dir}/output/rootfs.tar.gz
}
#copy=========================================================

#clean output dir=========================================================
clean_output_dir(){
	rm -rf ${temp_root_dir}/output/*
}
#clean output dir=========================================================

build(){
	check_env
	update_env
	echo "clean log ..."
	clean_log
	echo "clean output dir ..."
	clean_output_dir
	build_uboot
	echo "copy uboot ..."
	copy_uboot
	build_linux
	echo "copy linux ..."
	copy_linux
	build_buildroot
	echo "copy buildroot ..."
	copy_buildroot
}


#pack_tf_image==========================================================
pack_tf_normal_size_img(){
	_ROOTFS_FILE=${temp_root_dir}/output/rootfs.tar.gz
	_ROOTFS_SIZE=`gzip -l $_ROOTFS_FILE | sed -n '2p' | awk '{print $2}'`
	_ROOTFS_SIZE=`echo "scale=3;$_ROOTFS_SIZE/1024/1024" | bc`

	_UBOOT_SIZE=1
	_CFG_SIZEKB=0
	_P1_SIZE=16
	_IMG_SIZE=200
	_kernel_mod_dir_name=$(ls ${temp_root_dir}/output/modules/lib/modules/)
	_MOD_FILE=${temp_root_dir}/output/modules/lib/modules/${_kernel_mod_dir_name}
	_MOD_SIZE=`du $_MOD_FILE --max-depth=0 | cut -f 1`
	_MOD_SIZE=`echo "scale=3;$_MOD_SIZE/1024" | bc`
	_MIN_SIZE=`echo "scale=3;$_UBOOT_SIZE+$_P1_SIZE+$_ROOTFS_SIZE+$_MOD_SIZE+$_CFG_SIZEKB/1024" | bc` #+$_OVERLAY_SIZE
	_MIN_SIZE=$(echo "$_MIN_SIZE" | bc)
	echo  "--->min img size = $_MIN_SIZE MB"
	_MIN_SIZE=$(echo "${_MIN_SIZE%.*}+1"|bc)

	_FREE_SIZE=`echo "$_IMG_SIZE-$_MIN_SIZE"|bc`
	_IMG_FILE=${temp_root_dir}/output/image/lichee-zero-normal-size.img
	mkdir -p ${temp_root_dir}/output/image
	rm $_IMG_FILE
	dd if=/dev/zero of=$_IMG_FILE bs=1M count=$_IMG_SIZE
	if [ $? -ne 0 ]
	then
		echo  "getting error in creating dd img!"
	    	exit
	fi
	_LOOP_DEV=$(sudo losetup -f)
	if [ -z $_LOOP_DEV ]
	then
		echo  "can not find a loop device!"
		exit
	fi
	sudo losetup $_LOOP_DEV $_IMG_FILE
	if [ $? -ne 0 ]
	then
		echo  "dd img --> $_LOOP_DEV error!"
		sudo losetup -d $_LOOP_DEV >/dev/null 2>&1 && exit
	fi
	echo  "--->creating partitions for tf image ..."
	#blockdev --rereadpt $_LOOP_DEV >/dev/null 2>&1
	# size only can be integer
	cat <<EOT |sudo  sfdisk $_IMG_FILE
${_UBOOT_SIZE}M,${_P1_SIZE}M,c
,,L
EOT

	sleep 2
	sudo partx -u $_LOOP_DEV
	sudo mkfs.vfat ${_LOOP_DEV}p1 ||exit
	sudo mkfs.ext4 ${_LOOP_DEV}p2 ||exit
	if [ $? -ne 0 ]
	then
		echo  "error in creating partitions"
		sudo losetup -d $_LOOP_DEV >/dev/null 2>&1 && exit
		#sudo partprobe $_LOOP_DEV >/dev/null 2>&1 && exit
	fi

	#pack uboot
	echo  "--->writing u-boot-sunxi-with-spl to $_LOOP_DEV"
	# sudo dd if=/dev/zero of=$_LOOP_DEV bs=1K seek=1 count=1023  # clear except mbr
	_UBOOT_FILE=${temp_root_dir}/output/u-boot-sunxi-with-spl.bin
	sudo dd if=$_UBOOT_FILE of=$_LOOP_DEV bs=1024 seek=8
	if [ $? -ne 0 ]
	then
		echo  "writing u-boot error!"
		sudo losetup -d $_LOOP_DEV >/dev/null 2>&1 && exit
		#sudo partprobe $_LOOP_DEV >/dev/null 2>&1 && exit
	fi

	sudo sync
	mkdir -p ${temp_root_dir}/output/p1 >/dev/null 2>&1
	mkdir -p ${temp_root_dir}/output/p2 > /dev/null 2>&1
	sudo mount ${_LOOP_DEV}p1 ${temp_root_dir}/output/p1
	sudo mount ${_LOOP_DEV}p2 ${temp_root_dir}/output/p2
	echo  "--->copy boot and rootfs files..."
	sudo rm -rf  ${temp_root_dir}/output/p1/* && sudo rm -rf ${temp_root_dir}/output/p2/*

	#pack linux kernel
	_KERNEL_FILE=${temp_root_dir}/output/zImage
	_DTB_FILE=${temp_root_dir}/output/sun8i-v3s-licheepi-zero.dtb
	sudo cp $_KERNEL_FILE ${temp_root_dir}/output/p1/zImage &&\
        sudo cp $_DTB_FILE ${temp_root_dir}/output/p1/ &&\
        sudo cp ${temp_root_dir}/output/boot.scr ${temp_root_dir}/output/p1/ &&\
        echo "--->p1 done~"
        sudo tar xzvf $_ROOTFS_FILE -C ${temp_root_dir}/output/p2/ &&\
        echo "--->p2 done~"
        # sudo cp -r $_OVERLAY_BASE/*  p2/ &&\
        # sudo cp -r $_OVERLAY_FILE/*  p2/ &&\
        sudo mkdir -p ${temp_root_dir}/output/p2/lib/modules/${_kernel_mod_dir_name}/ &&\
        sudo cp -r $_MOD_FILE/*  ${temp_root_dir}/output/p2/lib/modules/${_kernel_mod_dir_name}/
        echo "--->modules done~"

        if [ $? -ne 0 ]
        then
		echo "copy files error! "
		sudo losetup -d $_LOOP_DEV >/dev/null 2>&1
		sudo umount ${_LOOP_DEV}p1  ${_LOOP_DEV}p2 >/dev/null 2>&1
		exit
        fi
        echo "--->The tf card image-packing task done~"
	sudo sync
	sleep 2
	sudo umount ${temp_root_dir}/output/p1 ${temp_root_dir}/output/p2  && sudo losetup -d $_LOOP_DEV
	if [ $? -ne 0 ]
	then
		echo  "umount or losetup -d error!!"
		exit
	fi
}
#pack=========================================================

if [ "${1}" = "" ] && [ ! "${1}" = "zero_spiflash" ] && [ ! "${1}" = "zero_tf" ] && [ ! "${1}" = "build_all" ] && [ ! "${1}" = "pull_all" ]; then
	echo "Usage: script.sh [zero_spiflash | zero_tf | pull_all | clean]"；
	echo "One key build nano finware";
	echo " ";
	echo "zero_spiflash    Build zero firmware booted from spiflash";
	echo "zero_tf          Build zero firmware booted from tf";
	echo "pull_all         Pull build env from internet";
	echo "pack             Pack all file for norflash rom (not rebuild)";
	echo "clean            Clean build env";
	echo "build            Build all";
    exit 0
fi

if [ ! -f ${temp_root_dir}/script.sh ]; then
	echo "Error:Please enter packge root dir"
    	exit 0
fi

if [ "${1}" = "update_env" ]; then
	update_env
	echo "update_env ok"
	exit 0
fi

if [ "${1}" = "clean" ]; then
	clean_all
	echo "clean ok"
	exit 0
fi

if [ "${1}" = "pull_all" ]; then
	pull_all
fi

if [ "${1}" = "pull_linux" ]; then
    pull_linux
fi

if [ "${1}" = "pull_buildroot" ]; then
    pull_buildroot
fi

if [ "${1}" = "build_uboot" ]; then
	u_boot_config_file="LicheePi_Zero_defconfig"
	build_uboot
fi

if [ "${1}" = "build_linux" ]; then
	linux_config_file="licheepi_zero_defconfig"
	build_linux
fi

if [ "${1}" = "build_buildroot" ]; then
    buildroot_config_file="licheepi_zero_defconfig"
	build_buildroot
fi

if [ "${1}" = "tf_pack" ]; then
    pack_tf_normal_size_img
fi

if [ "${1}" = "build_all" ]; then
	linux_config_file="licheepi_zero_defconfig"
	u_boot_config_file="LicheePi_Zero_defconfig"
	buildroot_config_file="licheepi_zero_defconfig"
	build
	pack_tf_normal_size_img
fi

sleep 1
echo "Done!"
