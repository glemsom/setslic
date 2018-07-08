## Description
Simple shell script to modify a VirtualBox VM to use a ACPI SLIC table, and set custom BIOS/System values.
The intention is to enable VirtualBox to run Windows using the builtin ACPI SLIC and MSDN table - to supply activation information.
Use at your own risk, might not work universally across all vendors. (Tested with Lenovo and newer Dell machines)

## Manage License in Windows
* During install, do select I do not have a key
* Install Windows and Guest Additions
* get an administrative CMD
	* slmgr /ipk <Product Key put out by setslic>
	* slmgr /ato
	* Windows should activate telling you it has used a digital License
* to revoke the key from a VM if you want to use it as a template:
	* slmgr /upk
	* slmgr /cpky
	* slmgr /rearm