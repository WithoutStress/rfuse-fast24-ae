# Experiment Guide for Chameleon Cloud Instance

This is guideline for reproducing results in the prepared snapshot image on ```storage-nvme``` instance of Chameleon Cloud. For claims and expectations of the artifact, please refer to [here](claims.md).

We recommend to use root account or root-previleged user account to avoid unintentional permission denied error. We do not include EXTFUSE in the evaluation as the EXTFUSE shows similar (even lower) performance for the benchmarks.

### 0. Before running benchmarks
* **Before performing each benchmarks, make sure that base device for StackFS and any user-level filesystem is not mounted on a mount point.** 
* For most of benchmarks below, we prepared convinience scripts (named ```cc_driver.sh```) that will evaluate performance of FUSE, RFUSE and EXT4.
* The scripts do not automatically build kernel driver of FUSE and RFUSE. Please build them before running the benchmarks.
    ```
    # (fuse kernel driver)
    $ cd driver/fuse
    $ make

    # (rfuse kernel driver)
    $ cd driver/rfuse
    $ make
    ```

* Execution logs will be stored under the top directory of each benchmarks. 
### 1. fio (Figure 8)

We have prepared the fio scripts to evaluate the throughput of FUSE, RFUSE with StackFS and EXT4. 

1\) Run fio benchmark script 
```
$ cd bench/fio
$ ./cc_driver.sh
```

### 2. scale_fio (Figure 10)

We have prepared the scale_fio scripts to evaluate the I/O scalability of FUSE, RFUSE (with StackFS) and EXT4. 

1\) Run scale_fio benchmark script 
```
$ cd bench/scale_fio
$ ./cc_driver.sh
```

### 3. fxmark (Figure 11)

We have prepared fxmark to evaluate the metadata operation scalability of FUSE and RFUSE. Since ```storage-nvme``` instance is equipped with 48 cores, a granularity of core count differs from what we show in Figure 11 in the paper. 
We exclude the `MWUL` and `MWUM` workloads from the scripts. These workloads involve saturating a filesystem until a CREATE operation returns the `ENOSPC` errno during the pre-work stage and executing UNLINK operations within a 30-second timeframe. 
Given that these scripts utilize the root file system as the base device in the instance, the process of cleaning up the base mount point requires a considerable amount of time, extending to several hours per running step and accumulating to several days in total.
Thus, we have uploaded results of these workloads extracted from the machine we used in the paper. Please refer to [here](fxmark/logs). 

1\) Build and install user library and kernel drivier of framework what you want to test

FUSE: 
```
# (libfuse)
$ cd lib/libfuse
$ ./libfuse_install.sh
	
# (fuse kernel driver)
$ cd driver/fuse
$ make 
$ ./fuse_insmod.sh first      # (if insmod the driver first time after reboot)
$ ./fuse_insmod.sh            # (if the driver is already insmoded)
```

RFUSE: 
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

2\) Build StackFS
```
$ cd filesystems/stackfs
$ make
```

3\) Run fxmark script
```
$ cd bin
$ ./cc-run-fxmark.py
```

### 4. filebench (Figure 12)
1\) Run filebench script 
```
$ cd bench/filebench 
$ ./cc_driver.sh
```

3\) Known Issues of filebench

* Filebench warns and recommends to disalble virtual address space randomization to provide stable filebench runs. If this feature is enabled, you may get ```Unexpected Process termination Code 3``` error. Our benchmark script disables this feature in advance when the script starts, but if you encount related error, please turn off it manually. 
    ```
    echo 0 > /proc/sys/kernel/randomize_va_space
    ```

### 5. Latency breakdown (Figure 2 and Figure 7)

We evaluate latency of single CREATE operations and breakdown its latency on FUSE and RFUSE in Figure 2 and Figure 7, respectively. The unit test performs single creat() operation on a mount point. In the library and kernel driver, they print timestamps at each breakdown points. For description of each breakdown points, please read comments on top of ```fuse/dev.c``` and ```rfuse/rfuse_dev.c```. 

1\) Build and install user-level library and kernel driver in Debug mode
   
* FUSE and RFUSE print timestamps of each breakdown point only in debug mode. Please build library and driver using debug options. We prepared the compiler configurations in each build scripts. See ```driver/rfuse/Makefile``` line 6 and ```lib/librfuse/meson.build``` line 77 (same file in FUSE).

2\) Mount NullFS 
```
$ cd filesystems/nullfs
$ make
$ ./run.sh
```

3\) Build unit test 
```
$ cd bench/unit
$ make
```

4\) Run unit test and get timestamp results
```
$ ./unit 1
```

[Expected Outputs](unit/unit_output.md)

5\) Calculate the latency between each timestamps
