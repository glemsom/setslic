#!/bin/bash
#
# Script for adding SLIC and related ACPI values to a VirtualBox VM
#
# By Glenn Sommer
#
#
# General Description ##########################################
# This script is used for converting a VirtualBox machine to a #
# SLIC aware machine. This will enable you to use your Windows #
# OEM license inside your VirtualMachine                       #
################################################################

# Procedure ####################################################
#                                                              #
# 1: Configure a VM in VirtualBox, and attach the Windows ISO  #
# 2: Run this script on the selected VM - take note of the     #
#    product key                                               #
# 3: Start the VM, and install Windows.                        #
#    Choose to NOT to enter a product key                      #
#    ( You might want to install Guest Tools, so you can       #
#      drag&drop content )                                     #
# 4: Install certificate / product key                         #
#    Start cmd.exe as administrator, and issue:                #
#     > slmgr -ilc <path xrn.ms file>                          #
#     ( wait about 5 seconds )                                 #
#     > slmgr -ipk <your product key>                          #
#     ( You will now get confirmation about the activation )   #
# DONE!                                                        #
################################################################

# Tips / Links #################################################
# REALLY YOU SHOULD READ THOSE LINKS !!                        #
# http://www.squidworks.net/2015/03/how-to-windows-7-oem-activation/
# https://www.facebook.com/notes/tharinda-lasitha/backup-and-reuse-your-windows-7-oem-license-slic-certificate-key-token-and-more/10151361974083659/
# https://www.microsoft.com/software-download/windows10ISO     #
################################################################

# Requirements #################################################
# - sudo, zenity and dmidecode  must be in place               #
# - A working VirtualBox installation                          #
################################################################


cfgPath="VBoxInternal/Devices/pcbios/0/Config"

# Simple error handler ########################################
errorHandle() {
	local message="$1"
	echo "ERROR: $message"
	exit 1
}
###############################################################

# function to get DMI information #############################
getDMI() {
	local dtype="$1"
	local entry="$2"
	local field="${3:-false}"
	local delimiter="${4:-.}"

	if [ $field == false ]; then
		val=$($dmidecode -t "$dtype" | grep -m 1 "^	${entry}:" | sed "s/.*${entry}: //")
	else
		val=$($dmidecode -t "$dtype" | grep -m 1 "^	${entry}:" | sed "s/.*${entry}: //" | cut -d $delimiter -f $field)
	fi
	if [ -n "$val" ]; then
		echo "$val"
	else
		errorHandle "Cannot find value for $dtype"		
	fi
}
################################################################


# Setup basic commands used later ##############################
sudo=$(which sudo) || errorHandle "sudo not found"
zenity=$(which zenity) || errorHandle "zenity no found"
dmidecodeBin=$(sudo which dmidecode) || errorHandle "dmidecode not found"
vboxmanage=$(which vboxmanage) || errorHandle "vboxmanage not found"
dmidecode="sudo $dmidecodeBin"
################################################################


# Fetch DMI information ########################################
DmiBIOSVendor=$(getDMI BIOS Vendor)
DmiBIOSVersion=$(getDMI BIOS Version)
DmiBIOSReleaseDate=$(getDMI BIOS "Release Date")
DmiBIOSReleaseMajor=$(getDMI BIOS "BIOS Revision" 1)
DmiBIOSReleaseMinor=$(getDMI BIOS "BIOS Revision" 2)
DmiBIOSFirmwareMajor=$(getDMI BIOS "Firmware Revision" 1)
DmiBIOSFirmwareMinor=$(getDMI BIOS "Firmware Revision" 2)
DmiSystemVendor=$(getDMI SYSTEM Manufacturer)
DmiSystemProduct=$(getDMI SYSTEM "Product Name")
DmiSystemVersion=$(getDMI SYSTEM "Version")
DmiSystemSerial=$(getDMI SYSTEM "Serial Number")
DmiSystemUuid=$(getDMI SYSTEM UUID)
DmiSystemSKU=$(getDMI SYSTEM "SKU Number")
DmiSystemFamily=$(getDMI SYSTEM Family)
DmiBoardProduct=$(getDMI BASEBOARD "Product Name")
DmiBoardSerial=$(getDMI BASEBOARD "Serial Number")
DmiBoardVendor=$(getDMI BASEBOARD Manufacturer)
DmiBoardVersion=$(getDMI BASEBOARD Version)

DmiBoardAssetTag=$(getDMI BASEBOARD "Asset Tag")
DmiBoardLocInChass=$(getDMI BASEBOARD "Location In Chassis")
#DmiBoardBoardType=$(getDMI BASEBOARD Type)
# Motherboard = 10
DmiBoardBoardType=10

DmiChassisVendor=$(getDMI CHASSIS Manufacturer)
#DmiChassisType=$(getDMI CHASSIS Type)
# Notebook = 10
DmiChassisType=10
DmiChassisVersion=$(getDMI CHASSIS Version)
DmiChassisSerial=$(getDMI CHASSIS "Serial Number")
DmiChassisAssetTag=$(getDMI CHASSIS "Asset Tag")

DmiProcManufacturer=$(getDMI PROCESSOR Manufacturer)
DmiProcVersion=$(getDMI PROCESSOR Version)

# DELL Fix ####################################################
if [[ "$DmiBIOSFirmwareMajor" == *"ERROR"* ]]; then
	DmiBIOSFirmwareMajor=$DmiBIOSReleaseMajor
	echo "This seems to be a DELL system, fixing BIOS Major Firmware version info..."
fi
if [[ "$DmiBIOSFirmwareMinor" == *"ERROR"* ]]; then
	DmiBIOSFirmwareMinor=$DmiBIOSReleaseMinor
	echo "This seems to be a DELL system, fixing BIOS Minor Firmware version info..."
fi
###############################################################

# Choose VM ###################################################
vmList=$($vboxmanage list vms | tr '{' '\n' | sed -e 's/"//g' -e 's/}//g') 
vm=$(echo "$vmList" | $zenity --list --print-column=2 --height=300 --width=500 --title="Choose a VM" --column="name" --column="UUID")
[ -z "$vm" ] && errorHandle "No VM selected"
###############################################################


# Fetch data path of VM #######################################
path=$(dirname "`$vboxmanage showvminfo "$vm" | grep 'Config file' | cut -d: -f2 | sed -e 's/^[ \t]*//'`")
[ -z "$path" ] && errorHandle "Unable to find VM path"
##############################################################

# Setup SLIC table  ##########################################
sudo dd if=/sys/firmware/acpi/tables/SLIC of="${path}/SLIC.BIN" || errorHandle "Unable to copy SLIC to $path"
$vboxmanage setextradata "${vm}" VBoxInternal/Devices/acpi/0/Config/CustomTable "${path}/SLIC.BIN" || errorHandle "Unable to set SLIC"
##############################################################


# Configure ACPI values #####################################
cfgCmd="$vboxmanage setextradata {${vm}} $cfgPath"
dmiElements=( DmiBIOSVendor DmiBIOSVersion DmiBIOSReleaseDate DmiBIOSReleaseMajor DmiBIOSReleaseMinor DmiBIOSFirmwareMajor DmiBIOSFirmwareMinor DmiSystemVendor \
		DmiSystemProduct DmiSystemVersion DmiSystemSerial DmiSystemUuid DmiSystemSKU DmiSystemFamily DmiBoardProduct DmiBoardSerial DmiBoardVendor DmiBoardVersion \
		DmiBoardAssetTag DmiBoardLocInChass DmiBoardBoardType \
		DmiChassisVendor DmiChassisType DmiChassisVersion DmiChassisSerial DmiChassisAssetTag \
		DmiProcManufacturer DmiProcVersion )
for element in ${dmiElements[@]}; do
	${cfgCmd}/${element} "$(eval echo $`echo $element`)"
done
#############################################################

# Get product key from MSDM table ###########################
productKey=$(sudo hexdump -s 56 -e '/29 "%s\n"' /sys/firmware/acpi/tables/MSDM)
[ -z "$productKey" ] && errorHandle "Error fetching product key from acpi table MSDM"
echo "Your product key is: $productKey"
$zenity --info --height=70 --width=400 --text "Your product key is: $productKey"
############################################################
