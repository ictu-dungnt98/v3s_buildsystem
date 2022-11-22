#!/bin/bash

#sdcard format
SDCARD=""

echo "Lichee pi Zero (V3S)"
echo "Welcome to use lichee pi nano sdk"
toolchain_dir="toolchain"
cross_compiler="arm-linux-gnueabihf"
temp_root_dir=$PWD

#uboot=========================================================
u_boot_dir="Lichee-Pi-u-boot"
u_boot_config_file=""
u_boot_boot_cmd_file="boot.cmd"
uboot_file="u-boot-sunxi-with-spl.bin"
#linux opt=========================================================
linux_dir="Lichee-Pi-linux"
linux_config_file=""
dtb_file="sun8i-v3s-licheepi-zero.dtb"
# dtb_file="sun8i-v3s-licheepi-zero-dock.dtb"
#buildroot opt=========================================================
buildroot_dir="buildroot"
buildroot_config_file=""

#pull===================================================================
pull_uboot(){
	rm -rf ${temp_root_dir}/${u_boot_dir} &&\
	git clone -b v3s-spi-experimental https://github.com/Lichee-Pi/u-boot.git ${temp_root_dir}/${u_boot_dir}
	if [ ! -d ${temp_root_dir}/${u_boot_dir} ]; then
		echo "Error:pull u_boot failed"
    		exit 0
	else
		echo "pull u-boot ok"
	fi
}

pull_linux(){
	rm -rf ${temp_root_dir}/${linux_dir} &&\
	#git clone -b zero-5.2.y https://github.com/Lichee-Pi/linux.git ${temp_root_dir}/${linux_dir}
    git clone -b zero-4.13.y https://github.com/Lichee-Pi/linux.git ${temp_root_dir}/${linux_dir}

	if [ ! -d ${temp_root_dir}/${linux_dir} ]; then
		echo "Error:pull linux failed"
    		exit 0
	else
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
	sudo rm -rf ${temp_root_dir}/${buildroot_dir}
	#wget https://buildroot.org/downloads/buildroot-2017.08.tar.gz && tar -xvf buildroot-2017.08.tar.gz
    git clone https://github.com/Unturned3/v3s_buildroot.git ${temp_root_dir}/${buildroot_dir}

    if [ ! -d ${temp_root_dir}/${buildroot_dir} ]; then
		echo "Error:pull buildroot failed"
    	exit 0
	else
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
        echo "build uboot.src"
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
        	echo "Error: LINUX NOT BUILD. Please Get Some Error From build_linux.log"
        	exit 1
	fi

	if [ ! -f ${temp_root_dir}/${linux_dir}/arch/arm/boot/dts/${dtb_file} ]; then
        	echo "Error: Linux NOT BUILD. ${temp_root_dir}/${linux_dir}/arch/arm/boot/dts/${dtb_file} not found"
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
	cd ${temp_root_dir}/${buildroot_dir}
	echo "Building buildroot ..."
    	echo "--->Configuring ..."
	rm ${temp_root_dir}/${buildroot_dir}/.config
	make ${buildroot_config_file}
	if [ $? -ne 0 ] || [ ! -f ${temp_root_dir}/${buildroot_dir}/.config ]; then
		echo "Error: .config file not exist"
		exit 1
	fi

    echo "--->Get cpu info ..."
    proc_processor=$(grep 'processor' /proc/cpuinfo | sort -u | wc -l)
	echo "--->Compiling ..."
  	make -j${proc_processor} > ${temp_root_dir}/build_buildroot.log 2>&1

	if [ $? -ne 0 ] || [ ! -d ${temp_root_dir}/${buildroot_dir}/output/target ]; then
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
	cp ${temp_root_dir}/${linux_dir}/arch/arm/boot/dts/${dtb_file} ${temp_root_dir}/output/
	mkdir -p ${temp_root_dir}/output/modules/
	cp -rf ${temp_root_dir}/${linux_dir}/out/lib ${temp_root_dir}/output/modules/
}
copy_buildroot(){
	cp -r ${temp_root_dir}/${buildroot_dir}/output/target ${temp_root_dir}/output/rootfs/ > /dev/null 2>&1
	cp ${temp_root_dir}/${buildroot_dir}/output/images/rootfs.tar ${temp_root_dir}/output/
	gzip -c ${temp_root_dir}/output/rootfs.tar > ${temp_root_dir}/output/rootfs.tar.gz
}
#copy=========================================================

#clean output dir=========================================================
clean_output_dir(){
	sudo rm -rf ${temp_root_dir}/output/*
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


#pack=========================================================
pack_spiflash_normal_size_img(){
    cd ${temp_root_dir}

    #rootfs
	sudo rm -rf ${temp_root_dir}/output/rootfs && mkdir -p ${temp_root_dir}/output/rootfs
	tar -C ${temp_root_dir}/output/rootfs -xvf ${temp_root_dir}/output/rootfs.tar > /dev/null 2>&1
	sudo chown root ${temp_root_dir}/output/rootfs/bin/* -R
	sudo cp ${temp_root_dir}/interfaces ${temp_root_dir}/output/rootfs/etc/network/interfaces

	#add config files
	sudo cp ${temp_root_dir}/interfaces ${temp_root_dir}/output/rootfs/etc/network/interfaces &&\
    sudo cp ${temp_root_dir}/service_ntp/S43hunonic_ntp ${temp_root_dir}/output/rootfs/etc/init.d/ &&\
	sudo cp ${temp_root_dir}/service_audio/S41hunonic_audio ${temp_root_dir}/output/rootfs/etc/init.d/ &&\
	sudo cp ${temp_root_dir}/service_audio/file_example_WAV_1MG.wav ${temp_root_dir}/output/rootfs/root/ &&\
	sudo chown root ${temp_root_dir}/output/rootfs/etc/init.d/S41hunonic_audio -R
	sudo chmod 777 ${temp_root_dir}/output/rootfs/etc/init.d/S41hunonic_audio

	#add user app file
	sudo cp /home/dungnt98/hunonic_gateway_app/sources/manager/build_manager_service/manager_service \
			${temp_root_dir}/output/rootfs/root/app
	sudo chown root ${temp_root_dir}/output/rootfs/root/app -R
	sudo chmod 777 ${temp_root_dir}/output/rootfs/root/app

	#add wifi config
	# sudo cp ${temp_root_dir}/wifi/wpa_supplicant.conf ${temp_root_dir}/output/rootfs/etc/
	# sudo cp ${temp_root_dir}/wifi/S42hunonic_wifi ${temp_root_dir}/output/rootfs/etc/init.d/ &&\
	# sudo chown root ${temp_root_dir}/output/rootfs/etc/init.d/S42hunonic_wifi -R
	# sudo chmod 777 ${temp_root_dir}/output/rootfs/etc/init.d/S42hunonic_wifi
	#add config wifi

	sudo mkfs.jffs2 -s 0x100 -e 0x10000 -p 0x1AF0000 -d ${temp_root_dir}/output/rootfs/ -o ${temp_root_dir}/output/jffs2.img


    OUT_FILENAME=${temp_root_dir}/output/flashimg.bin
    UBOOT_FILE=${temp_root_dir}/output/${uboot_file}	
	DTB_FILE=${temp_root_dir}/output/${dtb_file}

	KERNEL_FILE=${temp_root_dir}/output/zImage
    ROOTFS_FILE=${temp_root_dir}/output/jffs2.img

    dd if=/dev/zero 	of=$OUT_FILENAME bs=1M count=16 #flash 16M
    dd if=$UBOOT_FILE 	of=$OUT_FILENAME bs=1K conv=notrunc 
    dd if=$DTB_FILE 	of=$OUT_FILENAME bs=1K seek=1024  conv=notrunc
	dd if=$KERNEL_FILE 	of=$OUT_FILENAME bs=1K seek=1088  conv=notrunc
    dd if=$ROOTFS_FILE 	of=$OUT_FILENAME bs=1K seek=5184 conv=notrunc

	echo "done"
    #rm -rf ${temp_root_dir}/output/rootfs ${temp_root_dir}/output/jffs2.img
}

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
	fi

	#pack uboot
	echo  "--->writing u-boot-sunxi-with-spl to $_LOOP_DEV"
	_UBOOT_FILE=${temp_root_dir}/output/${uboot_file}
	sudo dd if=$_UBOOT_FILE of=$_LOOP_DEV bs=1024 seek=8
	if [ $? -ne 0 ]
	then
		echo  "writing u-boot error!"
		sudo losetup -d $_LOOP_DEV >/dev/null 2>&1 && exit
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
	_DTB_FILE=${temp_root_dir}/output/${dtb_file}
	sudo cp $_UBOOT_FILE ${temp_root_dir}/output/p1/${uboot_file} &&\
	sudo cp $_KERNEL_FILE ${temp_root_dir}/output/p1/zImage &&\
	sudo cp $_DTB_FILE ${temp_root_dir}/output/p1/ &&\
	sudo cp ${temp_root_dir}/output/boot.scr ${temp_root_dir}/output/p1/ &&\
	echo "--->p1 done~"

	sudo tar xzvf $_ROOTFS_FILE -C ${temp_root_dir}/output/p2/ > /dev/null 2>&1  &&\
	echo "--->p2 done~"
	#kernel module
	sudo mkdir -p ${temp_root_dir}/output/p2/lib/modules/${_kernel_mod_dir_name}/ &&\
	sudo cp -r $_MOD_FILE/*  ${temp_root_dir}/output/p2/lib/modules/${_kernel_mod_dir_name}/ &&\
	echo "--->modules done~"

	#add config files
	sudo cp ${temp_root_dir}/interfaces ${temp_root_dir}/output/p2/etc/network/interfaces &&\
    sudo cp ${temp_root_dir}/service_ntp/S43hunonic_ntp ${temp_root_dir}/output/p2/etc/init.d/ &&\
    sudo cp ${temp_root_dir}/service_audio/S41hunonic_audio ${temp_root_dir}/output/p2/etc/init.d/ &&\
	sudo cp ${temp_root_dir}/service_audio/file_example_WAV_1MG.wav ${temp_root_dir}/output/p2/root/ &&\

	sudo chown root ${temp_root_dir}/output/p2/etc/init.d/S41hunonic_audio -R
	sudo chmod 777 ${temp_root_dir}/output/p2/etc/init.d/S41hunonic_audio -R
	sudo chown root ${temp_root_dir}/output/p2/bin/* -R

    #add user app file
	# sudo cp /home/dungnt98/hunonic_gateway_app/sources/manager/build_manager_service/manager_service \
	# 		${temp_root_dir}/output/p2/root/app
	# sudo chown root ${temp_root_dir}/output/p2/root/app -R
	# sudo chmod 777 ${temp_root_dir}/output/p2/root/app

	#add wifi config
	sudo cp ${temp_root_dir}/service_wifi/wpa_supplicant.conf ${temp_root_dir}/output/p2/etc/
	sudo cp ${temp_root_dir}/service_wifi/S42hunonic_wifi ${temp_root_dir}/output/p2/etc/init.d/ &&\
	sudo chown root ${temp_root_dir}/output/p2/etc/init.d/S42hunonic_wifi -R
	sudo chmod 777 ${temp_root_dir}/output/p2/etc/init.d/S42hunonic_wifi -R

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

umount_all()
{
	set +e

	sudo df | grep ${SDCARD}1 2>&1 1>/dev/null
	if [ $? == 0 ]; then
		sudo umount ${SDCARD}1
	fi

	sudo df | grep ${SDCARD}2 2>&1 1>/dev/null
	if [ $? == 0 ]; then
		sudo umount ${SDCARD}2
	fi

	set -e
}

if [ "${1}" = "" ] && [ ! "${1}" = "build_tf" ] && [ ! "${1}" = "build_flash" ] && [ ! "${1}" = "pull_all" ]; then
	echo "Usage: script.sh [build_flash | build_tf | pull_all | clean]"；
	echo "One key build nano fimware";
	echo " ";
	echo "build_flash    Build zero firmware booted from spiflash";
	echo "build_tf          Build zero firmware booted from tf";
	echo "pull_all         Pull build env from internet";
	echo "clean            Clean build env";
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
    clean_output_dir
	echo "clean ok"
	exit 0
fi

if [ "${1}" = "pull_all" ]; then
	pull_all
fi

if [ "${1}" = "pull_uboot" ]; then
    pull_uboot
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

if [ "${1}" = "build_tf" ]; then
	cp -f ${temp_root_dir}/linux_tf_sun8i.h ${temp_root_dir}/${u_boot_dir}/include/configs/sun8i.h
	cp -f ${temp_root_dir}/sun8i-v3s-licheepi-zero.dts ${temp_root_dir}/${linux_dir}/arch/arm/boot/dts/
    cp -f ${temp_root_dir}/sun8i-v3s.dtsi ${temp_root_dir}/${linux_dir}/arch/arm/boot/dts/

	cp -f ${temp_root_dir}/v3s_buildroot_defconfig \
		${temp_root_dir}/${buildroot_dir}/configs/licheepi_zero_defconfig

	linux_config_file="licheepi_zero_defconfig"
	u_boot_config_file="LicheePi_Zero_defconfig"
	buildroot_config_file="licheepi_zero_defconfig"

	build
	# pack_tf_normal_size_img
fi

if [ "${1}" = "pack_tf" ]; then
    pack_tf_normal_size_img
fi

if [ "${1}" = "burn_tf" ]; then
	echo "umounting sdcard..."
	SDCARD="/dev/sda"
	umount_all
	echo "deleting all partitions..."
	sudo wipefs -a -f $SDCARD
	# TODO  can this really work?
	sudo dd if=/dev/zero of=$SDCARD bs=1M count=1
	echo "creating partitions..."
	sudo fdisk $SDCARD < part.txt
	echo "formating partitions..."
	sudo mkfs.ext4 -F ${SDCARD}1

	sudo dd if=${temp_root_dir}/output/image/lichee-zero-normal-size.img of=/dev/sda bs=1M conv=notrunc
	sudo sync
fi

if [ "${1}" = "create_tf_fel" ]; then
	echo "umounting sdcard..."
	SDCARD="/dev/sda"
	umount_all
	echo "deleting all partitions..."
	sudo wipefs -a -f $SDCARD
	# TODO  can this really work?
	sudo dd if=/dev/zero of=$SDCARD bs=1M count=1
	echo "creating partitions..."
	sudo fdisk $SDCARD < part.txt
	echo "formating partitions..."
	sudo mkfs.ext4 -F ${SDCARD}1

	sudo dd if=~/fel-sdboot.sunxi of=/dev/sda bs=1M conv=notrunc
	sudo sync
fi

if [ "${1}" = "build_flash" ]; then
	cp -f ${temp_root_dir}/linux_flash_sun8i.h ${temp_root_dir}/${u_boot_dir}/include/configs/sun8i.h
	cp -f ${temp_root_dir}/spi-nor.c ${temp_root_dir}/${linux_dir}/drivers/mtd/spi-nor/spi-nor.c
	cp -f ${temp_root_dir}/sun8i-v3s-licheepi-zero.dts ${temp_root_dir}/${linux_dir}/arch/arm/boot/dts/
    cp -f ${temp_root_dir}/sun8i-v3s.dtsi ${temp_root_dir}/${linux_dir}/arch/arm/boot/dts/

	cp -f ${temp_root_dir}/uboot-licheepi_zero_spiflash_defconfig \	
		${temp_root_dir}/${u_boot_dir}/configs/LicheePi_Zero_defconfig
    cp -f ${temp_root_dir}/linux-licheepi_zero_spiflash_defconfig \
		${temp_root_dir}/${linux_dir}/arch/arm/configs/licheepi_zero_spiflash_defconfig
	cp -f ${temp_root_dir}/v3s_buildroot_defconfig \
		${temp_root_dir}/${buildroot_dir}/configs/licheepi_zero_defconfig

	u_boot_config_file="LicheePi_Zero_defconfig"
	linux_config_file="licheepi_zero_spiflash_defconfig"
    buildroot_config_file="licheepi_zero_defconfig"

	build
	pack_spiflash_normal_size_img

	echo "the binary file in output/ dir"
fi

if [ "${1}" = "pack_flash" ]; then
        pack_spiflash_normal_size_img
fi

if [ "${1}" = "burn_flash" ]; then
	sudo sunxi-fel -p spiflash-write 0x0 	 ${temp_root_dir}/erase_flash.bin
	sudo sunxi-fel -p spiflash-write 0x0 	 ${temp_root_dir}/output/u-boot-sunxi-with-spl.bin
	# sudo sunxi-fel -p spiflash-write 0x100000 ${temp_root_dir}/output/${dtb_file}
	# sudo sunxi-fel -p spiflash-write 0x110000 ${temp_root_dir}/output/zImage
	# sudo sunxi-fel -p spiflash-write 0x510000 ${temp_root_dir}/output/jffs2.img

	# sudo sunxi-fel -p spiflash-write 0 ${temp_root_dir}/output/flashimg.bin
fi

sleep 1
echo "Done!"

