
# RFUSE Artifact Evaluation [FAST '24]

This repository contains the artifact for reproducing our FAST '24 paper "RFUSE: Modernizing Userspace Filesystem Framework through Scalable Kernel-Userspace Communication". 

# Overview of the Artifact 
```
root      
|---- driver                   (Source code of kernel drivers) 
    |---- fuse          
    |---- rfuse  
|---- lib                      (Source code of user-level libraries)
    |---- libfuse          
    |---- librfuse            
|---- linux                    (Linux kernel 5.15.0)
|---- filesystems              (User level filesystems)
        |---- nullfs           (Source code of NullFS)
        |---- stackfs          (Source code of StackFS)
|---- bench        
    |---- unit                 (Unit test for latency breakdown; Figure 2 and Figure 7)
    |---- fio                  (Fio benchmark scripts; Figure 8)
    |---- scale_fio            (I/O scalability benchmark based on fio; Figure 10)
    |---- fxmark               (Fxmark benchmark source code and scripts; Figure 11)
    |---- filebench            (Filebench workloads and scripts; Figure 12)   
```


# Using Chameleon Cloud Instance

For artifact evaluation, we have prepared a snapshot image named ```rfuse_ae``` within the CHI@UC site of [Chameleon Cloud](https://www.chameleoncloud.org/), encompassing the artifact along with a fully configured environment. This image is designed to be executed on the ```storage-nvme``` node of Chameleon Cloud.

If you decide to use the snapshot image, you can skip [Get Started](#get-started) section below and please refer to [Experiment Guide for Chameleon Cloud Instance](bench/experiment_guide_for_cc.md).

# System Requirement (Tested Environment)

### 1. Hardware
* 2-socket x86_64 CPU (40 cores per socket)
* 256 GB DRAM
* PCIe Gen 4.0 NVMe SSD

### 2. Software 
* OS distribution: Ubuntu 20.04.5 LTS
* Linux kernel version: 5.15.0

### 3. Dependent packages 
```
sudo apt install build-essential make ninja-build meson pkg-config autoconf kernel-package libncurses5-dev bison flex libssl-dev fio python2
```

# Get Started

### 1. Clone the repository
```
$ git clone https://github.com/WithoutStress/rfuse-fast24-ae.git
$ cd rfuse-fast24-ae
```

### 2. Install the 5.15.0 Linux kernel 
```
$ cd linux 
$ sudo make menuconfig          # --> CONFIG_FUSE_FS=m

$ sudo make-kpkg -j N --initrd --revision=1.0 kernel_image kernel_headers
$ cd ..
$ sudo dpkg -i *.deb
```

### 3. Set per-core ring channel 

RFUSE uses per-core ring channel for request communication. Before installing user library and kernel driver, users should configure the number of ring channel as the number of CPU cores in the machine.
```
# (librfuse)
$ cd lib/librfuse 
$ vi include/rfuse.h

# (rfuse kernel driver)
$ cd driver/rfuse
$ vi rfuse.h

--> Change the value of RFUSE_NUM_IQUEUE to the number of core in machine.
```
### 4. Compile and install user library and kernel driver
```
# (librfuse)
$ cd lib/librfuse
$ ./librfuse_install.sh
	
# (rfuse kernel driver)
$ cd driver/rfuse
$ make 
$ ./rfuse_insmod.sh first      # (if insmod the driver first time after reboot)
$ ./rfuse_insmod.sh            # (if the driver is already insmoded)
```
* If you want to install native fuse user library and kernel driver, move to ```lib/libfuse``` and ```driver/fuse```, and run prepared installation scripts in that directories.
* Add the location of library into ```LD_LIBRARY_PATH``` (Add below line into ```.bashrc``` for system-wide adoption).
```
$ export LD_LIBRARY_PATH=/usr/local/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH}
```

### 5. Builld and mount user level filesystems
1\. NullFS

NullFS is a very simple userspace filesystem that only supports the STAT operation on the root directory. 
```
$ cd filesystems/nullfs
$ make
$ ./run.sh
```

2\. StackFS

StackFS is a stackable userspace filesystem that forwards incoimming filesystem operations to an underlying in-kernel filesystem. To mount StackFS, users need to set a base device for the underlying filesystem. Please configure ```DEVICE_NAME``` in ```stackfs/run.sh```.
If you are utilizing a Chameleon Cloud instance and tryting to build from scratch, please be aware that the `stackfs/run.sh` script only supports the option `ssd-noclean` because of the absensce of an additional device to be used for an underlying in-kernel filesystem. Consequently, the root filesystem is employed as the underlying file system.
```
$ cd filesystems/stackfs
$ make

$ ./run.sh ssd              # (Format base device first and mount StackFS)  
$ ./run.sh ssd-noclean      # (Mount StackFS without formatting base device)
```

# Experiments 

Please refer to [Experiment Guide](bench/README.md) if you build RFUSE from the scratch or, 

Please refer to [Experiment Guide for Chameleon Cloud Instance](bench/experiment_guide_for_cc.md) if you plan to use Chameleon Cloud instance we prepared.
