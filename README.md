# gen-uboot-img: msm8916 bootchain packaging helper

This is a quick experimental tool that allows one to build a EFI capable bootchain
for msm8916-based devices using lk2nd and experimental u-boot build.

> [!WARNING]
> This bootchain is **experimental** and relies on WIP code.

All devices supported by lk2nd and msm8916-mainline should be supported.

## Installation

You can get a prebuilt package from [releases](https://github.com/msm8916-mainline/gen-uboot-img/releases) page. See installation instruction below:

### Installation using the stock bootloader

Install `combined.img` into your `boot` partition:

 - Fastboot: `fastboot flash:raw boot combined.img`
 - Samsung: `heimdall flash --BOOT combined.img`

### Installation via existing lk2nd:

```
fastboot flash lk2nd lk2nd.img
fastboot flash qhypstub qhypstub.bin
fastboot flash boot thirdstage.ext2
```

## Building

You will need to collect a selection of projects to build the bootchain.

- WIP lk2nd branch: `rebase/next` from [msm8916-mainline/lk2nd](https://github.com/msm8916-mainline/lk2nd)
- Linux kernel: Latest branch from [msm8916-mainline/linux](https://github.com/msm8916-mainline/linux)
- Linaro's Qcom Landing Team U-Boot tree: `caleb/rbx-integration` from [linaro/qcomlt/u-boot](https://git.codelinaro.org/linaro/qcomlt/u-boot)
- qhypstub: [msm8916-mainline/qhypstub](https://github.com/msm8916-mainline/qhypstub)

Build system expects those repositories to exist in the parent dir of the project.
See Makefile on how to override the path.

After collecting and checking out desired branches on these repositories, run:

```
make -j$(nproc)
```

This will builds all the projects and place artifacts in `build/`.

## Usage

U-Boot is configured to check if `power` button is pressed on the device and
show the menu. Boot the device, hold `power` when u-boot boots, then use
volume keys to pick `mmc 0` (emmc) or `mmc 1` (microsd) where you have your EFI
bootloader.
