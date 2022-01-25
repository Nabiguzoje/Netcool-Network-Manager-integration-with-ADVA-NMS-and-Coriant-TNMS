# Netcool-Network-Manager-integration-with-ADVA-NMS-and-Coriant-TNMS

## Introduction

This simple solution is integrating ADVA NMS and CORIANT TNSM with IBM Network Manager. Solution is providing architecture visualization and snmp traps integration with IBM Netcool Network Manager. Integration is done via SNMP protocol for CORIANT equipment and via SNMP and ADVA Fiber Service Platform for ADVA equipment. Such approach is avoiding CORBA interface. On IBM Network Manager side Generic CSV Collector is used for interpretation of provided data and population of required information in Network Manager topology databases. 

## ADVA NMS integration

ADVA FSP (Fiber Service Platform) is providing csv files that are describing configuration and topology of ADVA optical equipment. These files are used as input into Generic CSV collector of IBM Network Manager, and custom perl scrip is providing translation of data from FSM into csv files that are readable by Generic CSV collector

### Snippets from ADVA FSP files

Adva FSP provides two csv files that are descriping inventory and topology of hardware (in this case report is from FSP 3000R7, but scripts can be easily ajustet for newest revisions). Inventory CSV report file have 46 columns.

| Subnet | NE | ProductType | NEMI_SW_Version | ModuleName | ModuleType | OrderInfo | Channel | Protection | 
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
|``<string>``|``<string>``(IP address)|FSP 150CCf-825,FSP 150CC,FSP 150CM,FSP 150CP,FSP 150EG-M4,FSP 150EG-M8,FSP 150EG-X,FSP 150Mx,FSP 1500 STM-16,FSP 1500 STM-16 prot,FSP 1500 STM-4 prot,FSP 3000R7,HN4000,HN400|``<string>``|``<string>``|``<string>``|``<string>``|``<string>``|n/a,Unprotected,West,East|
|subnetwork name or IP address and the path to the subnetwork of the entry node in the subnetwork (e.g., Network/FSP3000R7, FSP 3000R7 is the subnetwork name)|The network element name (and IP address).|Indicates the product type.|The NEMI/NCU software version.|The AID of the module, as reported in the Shelf List in Chassis window or in the PDF Inventory Report.|The content of the column <Type>, used by the GUI and the column <ModuleType>, used by the PDF Inventory Report|The ADVA Optical Networking part number for each module|The channel of the module, e.g. “D14”.|Indicates whether the module is protected (West or East), Unprotected or n/a if it is not applicable for the module (filter).|

Rest of the columns are as following: _Name,Clock,InstalledAt,HWRevision,FWRevision,SWRevision,SerialNumber,Assignment,ServiceName,CustomField,CustomSubnetField,Location,Rack,Shelf,ShelfHWRevision,ShelfSerialNumber,ShelfModuleName,ShelfModuleType,ShelfName,ShelfInstalledAt,ShelfAssignment,ShelfOrderInfo,AdminState,OperState,econdaryState,UserTex,UserDescr,IdentificationKey,IdentificationValue,ProvisionedModuleType,EquippedModuleType,SI2_ShelfIndex,SI3_SlotIndex,SI4_SubSlotIndex,Alias,NELocation,CountryOfOrigin_

Topology CSV reports provides connections from Node and Port A, to Node and Port Z, Line name and eventually Outer VLAN tags A to Z and Outer VLAN tags Z to A
	
These two files are used as data info for population of Network Manager Topology database
	
## View of Adva topology and Adva device in IBM Netcool Network Manager View
	
/assets/images/adva_topology.png
																																													

