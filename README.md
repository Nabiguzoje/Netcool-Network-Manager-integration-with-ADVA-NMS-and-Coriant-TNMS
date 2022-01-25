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
	
### View of Adva topology and Adva device in IBM Netcool Network Manager View

End product of Adva topology integration in IBM Netcool Network Manager Network View should look smilar to this:	
	
![Adva Toplogy](https://github.com/Nabiguzoje/Netcool-Network-Manager-integration-with-ADVA-NMS-and-Coriant-TNMS/blob/main/adva_topology.png?raw=true)

And hardware inventory of one of the devices in IBM Netcool Network Manager Device View should look something like this:
	
![Adva Toplogy](https://github.com/Nabiguzoje/Netcool-Network-Manager-integration-with-ADVA-NMS-and-Coriant-TNMS/blob/main/adva_device.png?raw=true)

Note that all severity informations are correctly indicated on respectet devices.

### Configuration of IBM Netcool Network Manager Generic CSV Collector

Information on how to configure collectors can be found in offical IBM documentation for [Generic CSV Collector](https://www.ibm.com/docs/en/networkmanager/4.2.0?topic=collectors-configuring-genericcsv-collector)

In this specific case Generic CSV collector configuration file (GenericCsvCollector.cfg) was set like:
```	
(
    General =>
    {
        Debug => 0,
        Listen => 8081,
        QueueSize => 40
    },

    DataSource =>
    {
        CsvCfg => '/opt/IBM/netcool/core/precision/collectors/perlCollectors/CSV/GenericCsv.cfg',

        SourceInfo =>
        {
            Id => 1,
            Descr => 'Primary Data Source',
            # EmsHost => '',
            # EmsName => '',
            # EmsVersion => '',
            # EmsIdentifier => '',
            # EmsRole => '',
            # EmsStatus => '',
        },

        DataAcquisition =>
        {
            GetEntities => 1,
            GetLayer2Vpns => 0,
            GetLayer3Vpns => 0,
            GetLayer1Connections => 1,
            GetLayer2Connections => 0,
            GetLayer3Connections => 0,
            GetMplsInterfaces => 0
        }
    }
)
```	
Basically we have described the running port of collector (8081) and additional configuration file for parsing (GenericCsv.cfg). Parsing file is set like this:
```	
(
    system => {
        logfile => '/opt/IBM/netcool/core/precision/collectors/perlCollectors/CSV/genericCsv.log',
		verbose => 1,
		logging => 1 
	},

    driver => {
		file => '/opt/IBM/netcool/core/precision/collectors/perlCollectors/CSV/genericCsv.drv'
	},


  file => {

        MainEntityData      => '/opt/IBM/netcool/core/precision/collectors/perlCollectors/CSV/CsvData/devices.csv',
        GenericEntityData   => '/opt/IBM/netcool/core/precision/collectors/perlCollectors/CSV/CsvData/genericentities.csv',
 
        L1ConnectivityData  => '/opt/IBM/netcool/core/precision/collectors/perlCollectors/CSV/CsvData/layer1Links.csv',

    },
 lineMatch => {

        MainEntityData      => '.*',
        InterfaceData       => '.*',
    }
 delimeter => {

        MainEntityData      => '|',
        InterfaceData       => '|',
        EntityData          => '|',
        GenericEntityData   => '|',
        L3ConnectivityData  => '|',
        L2ConnectivityData  => '|',
        L1ConnectivityData  => '|',
        MicrowaveConnectivityData  => '|',
        L3VpnData           => '|',
        L3VpnInterfaceData  => '|',
        L3VpnRTData         => '|',
        L2VpnData           => '|',
        MplsInterfaceData   => '|', 
    }
)
```
This file defines names and delimiters of translated input files. Delimiter is set to '|' and files are _devices.csv, genericentities.csv,_ and _layer1Links.csv_

Device.csv file should contain basic information about SDH and DWDM network equipment
```	
<ip_address>|1|<device_name> (ip_address)|1.3.6.1.4.1.2544.1.11.1||<device_name> (ip_address)|1|<region>
<ip_address>|1|<device_name> (ip_address)|1.3.6.1.4.1.2544.1.11.1||<device_name> (ip_address)|1|<region>
<ip_address>|1|<device_name> (ip_address)|1.3.6.1.4.1.2544.1.11.1||<device_name> (ip_address)|1|<region>
<ip_address>|1|<device_name> (ip_address)|1.3.6.1.4.1.2544.1.11.1||<device_name> (ip_address)|1|<region>
```
genericentitites.csv file should contain modules that are present in device. I have randomized part numbers of devices, just in case.
```
<device_name> (ip_address)|FCU-1|6|FAN/Plug-In|SHELF-1|1|4.01|n/a|152.0.0|FA7232423434|Free
<device_name> (ip_address)|FCU-2|6|FAN/Plug-In|SHELF-2|17|4.01|n/a|152.0.0|FA73214321432445|Free
<device_name> (ip_address)|MOD-1-12|8|Slot 12-AGFB-8-B20-DAC-BC|SHELF-1|9|2.01|n/a|162.1.2|FA321321321|Assigned
```
And layer1Links.csv should contain links between devices.
```
<device_name> (ip_address)|OL-1|<device_name> (ip_address)|OL-2|1
<device_name> (ip_address)|OL-2|<device_name> (ip_address)|OL-1|1
<device_name> (ip_address)|OL-2|<device_name> (ip_address)|OL-3|1
```
### Parsing of ADVA FSP data to Generic CSV Collector format

Scrit [adva.pl](https://github.com/Nabiguzoje/Netcool-Network-Manager-integration-with-ADVA-NMS-and-Coriant-TNMS/blob/main/adva.pl) is used for translating one csv format data into other csv format data. All comments in this script are written in Croatian language, if required it can be alterd to English languague. Plus script is pretty much raw so that operators can run them blindy. 

