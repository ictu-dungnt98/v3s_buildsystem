#!/bin/bash

echo "Lichee pi Zero (V3S)"
echo "Welcome to use lichee pi nano sdk"
toolchain_dir="toolchain"
cross_compiler="arm-linux-gnueabi"
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
buildroot_dir="buildroot-2021.02.3"
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
	git clone -b zero-5.2.y https://github.com/Lichee-Pi/linux.git linux
	
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
    wget https://releases.linaro.org/components/toolchain/binaries/7.4-2019.02/arm-linux-gnueabi/gcc-linaro-7.4.1-2019.02-x86_64_arm-linux-gnueabi.tar.xz &&\
    tar xvJf gcc-linaro-7.4.1-2019.02-x86_64_arm-linux-gnueabi.tar.xz
    if [ ! -d ${temp_root_dir}/${toolchain_dir}/gcc-linaro-7.4.1-2019.02-x86_64_arm-linux-gnueabi ]; then
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
	wget https://buildroot.org/downloads/buildroot-2021.02.3.tar.gz && tar xvf buildroot-2021.02.3.tar.gz
	if [ ! -d ${temp_root_dir}/${buildroot_dir}/buildroot-2021.02.3 ]; then
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

#env===================================================================
update_env(){
	if [ ! -d ${temp_root_dir}/${toolchain_dir}/gcc-linaro-7.4.1-2019.02-i686_arm-linux-gnueabi ]; then
		if [ ! -d ${temp_root_dir}/${toolchain_dir}/gcc-linaro-7.4.1-2019.02-x86_64_arm-linux-gnueabi ]; then
			echo "Error:toolchain no found,Please use ./buid.sh pull_all "
	    		exit 0
		else			
			export PATH="$PWD/${toolchain_dir}/gcc-linaro-7.4.1-2019.02-x86_64_arm-linux-gnueabi/bin":"$PATH"
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

if [ ! -f ${temp_root_dir}/build.sh ]; then
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

if [ "${1}" = "build_uboot" ]; then
	u_boot_config_file="LicheePi_Zero_defconfig"
	build_uboot
fi

if [ "${1}" = "build_linux" ]; then
	build_linux
fi

if [ "${1}" = "build_buildroot" ]; then
	build_buildroot
fi


sleep 1
echo "Done!"