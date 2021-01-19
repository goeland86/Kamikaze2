# ReFactor
Simplified Thing-Printer board image generation toolset, based on Debian or Ubuntu images from RCN for beaglebone.

The starting point for ReFactor is the Ubuntu console image, details are in the wiki here:
http://wiki.thing-printer.com/index.php?title=ReFactor

ReFactor is a build-tool to install a printer's Firmware (at the moment Klipper), a printer control interface (OctoPrint or DWC), a touch-screen interface (Toggle w/ OctoPrint, DWC's tbd) and a few miscellaneous items (webcam streamer, network file share for gcode file uploads, etc.).

It sets a default password for access as root on new images (**root:kamikaze**), but leaves the root account alone otherwise.
SSH is meant to be active and allow root login. The `debian` user is normally also setup and runs OctoPrint and Klipper. Its password is set to `temppwd`. Both root and debian passwords will need to be changed upon first login.

## Usage

The images generated are focused on being a boot-strapped firmware for Thing-Printer control boards, such as Replicape and Recore. However PRs to make ReFactor an image generation tool for a wider range of single-board controllers is completely welcome. To support multiple platforms, the build script usage has been modified:
```
cd <path to Refactor git clone>
sudo ./build-image-in-chroot-end-to-end.sh <platform> [OPTIONAL: system setup script]
```
If not specified, the _ansible-playbook_ that is used is ___SYSTEM_klipper_octoprint-DEFAULT.yml___

The platform (required parameter) is one of:
 * replicape
 * recore
 * pi
 * pi64

The script then exports the `platform` ansible variable, and sources the `BaseLinux/$platform/Linux` file for a number of items:
* a URL for which base linux image to build from (pine64 armbian for `pi64` and `recore`, RCN-built console debian 10.3 for `replicape`, raspbian for `pi`)
* the `decompress()` function, to allow the script to properly decompress the downloaded file and export the image file to where it can be mounted
* additional ansible parameters specific to the platform requirements. For the moment this is where the `platform` gets passed through, as well as the `firmware` variable.

**IMPORTANT NOTE**: Only the `SYSTEM-[...].yml` playbook files can work with the `build-image-in-chroot-end-to-end.sh` script. The `INSTALL-[...].yml` playbooks are provided as means for end-users to customize their running images. It is inadvisable to run a `SYSTEM-[...].yml` playbook on an already running system. And especially not during a print. That would cause a division by zero and make the printer disappear into its own micro black hole. Or release the magic smoke. Either way, not a good thing. You have been warned.

### Example of running a task locally
`ansible-playbook INSTALL-toggle.yml --extra-vars '{platform: recore}'`

# Contributing

Any contribution you make should be in the form of a PR aimed at the `dev` branch of `intelligent-agent/Umikaze`. The `dev` branch will lead to the generation of a beta or release-candidate image for the community to test, and can be delayed for merge to `master` in case multiple changes arrive in a similar time frame, to release a new image with all new features combined.

If you are trying to fix a bug, please prefix the `PR` with `[bug]`, and mention the Github Issue # in the PR description.

In case you need help building an image to test your changes and do not have a build environment available, please submit your PR against `goeland86/ReFactor`, with a title prefixed with `[Dev]` to clearly identify that the features are still under active development.

# Latest images

To verify images and always test the latest code changes, a Jenkins unit is running to build images for any commit to the `master` branch.
Any tag created will generate a pre-release on the repository, with automatically generated and uploaded images attached.
If you want to test a specific commit's image, you'll need to browse the [Jenkins project](https://goeland86.hopto.org/job/IntelligentAgent-master-ReFactor/) to download the corresponding image (called artifact).

This Jenkins server is running on a pi 4, which means its capacity is limited to only one image build at a time, and despite the USB3 drive for I/O, an image for Replicape or Recore alone takes nearly an hour. It's also a recurring donation to the project by @goeland86 to keep it online and up to date.

# Previous image versions

Umikaze 2.1.1 was built on Ubuntu 18.04.1 (LTS) and incorporated OctoPrint, Redeem and Toggle.
To learn more about Umikaze, go to https://github.com/intelligent-agent/Umikaze/wiki

The starting point for Kamikaze 2.0.0 is the Debian IoT image found here:
https://debian.beagleboard.org/images/

For Kamikaze 1.0:  
    ssh root@kamikaze.local  
    cd /usr/src/  
    git clone http://github.org/eliasbakken/Kamikaze2  
    cd Kamikaze2  
    ./make-kamikaze-1.1.1.sh  

Here is how to recreate for Kamikaze 2.0:  
    ssh root@beaglebone.local  
    cd /usr/src/  
    git clone http://github.org/eliasbakken/Kamikaze2  
    cd Kamikaze2  
    ./make-kamikaze-2.0.0.sh  


The update command will kick the user out from the ssh session.

# Changelog:
2.2.0 - *** Work In Progress ***


2.1.1 - Support for BeagleBone Black Wireless! Fixed CPU governor to performance to guarantee full 1GHz clock speed at all times when printing. Included slic3r, upgraded to Octoprint 1.3.2, uses Redeem 2.0.0 tracking the staging branch to get updates sooner. Included PRU-software-support package to compile the new C PRU firmware from Redeem.

2.1.0 - Migrated from Debian IoT jessie base to Ubuntu 16.04.1LTS, using 4.1 LTS kernel, included 2 octoprint plugins (FileManager and Slicer) for nearly completely autonomous printer from the original setup. Switched from connman to Network-Manager, configuration done through console utility nmtui

2.0.0 - Kernel 4.4.20-bone13, cogl-1.22, clutter-1.26

1.1.1 - chown octo:octo on /etc/redeem and /etc/toggle

1.1.0 - Install latest Redeem, Toggle and OctoPrint from repositories.


