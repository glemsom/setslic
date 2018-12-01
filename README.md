## Description
Simple shell script to modify a VirtualBox VM to use a ACPI SLIC table, and set custom BIOS/System values.
The intention is to enable VirtualBox to run Windows using the builtin ACPI SLIC and MSDN table - to supply activation information.
Use at your own risk, might not work universally across all vendors. (Tested with Lenovo and newer Dell machines)

## Manage License in Windows
* During install, select: I do not have a product key"
* Install Windows and Guest Additions
* Get an administrative CMD
	* slmgr /ipk <Product Key put out by setslic>
	* slmgr /ato
	* Windows should activate telling you it has used a digital License
* To revoke the key from a VM if you want to use it as a template:
	* slmgr /upk
	* slmgr /cpky
	* slmgr /rearm

This script is from my blog at https://glemsomtechs.blogspot.com/2018/07/acpi-slic-in-virtualbox.html
Donation accepted at 14KGwX7e85vJLAbgRg2boGTqN5WEaBHAqP
