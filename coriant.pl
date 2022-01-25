#!/usr/bin/perl
###########################################################################################################################
#
#  Creating files for IBM Network Manager perlCollector from SNMP Tables
#
#
#  Author: Mislav Kasalo 
#  Email: mislav.kasalo@gmail.com
#
######################################


use strict;
use warnings;
use Data::Dumper qw(Dumper);


my $inputDevicesFilename = 'enmsNETable.csv'; # input file name definitions
my $modulesFilename = 'enmsModuleTable.csv';
my $portFilename = 'enmsPortTable.csv';
my $portConnFilename = 'enmsPortConnTable.csv';
my $delimiter = ";"; # input files delimiter


my %ldevices;  # hash for storing devices
my %dhash; # hash for storing key-value pairs of device name  - device id
my %pint; # hash for storing key-value  pairs of ports name - ports id
my %lchassis; # hash for storing modules in the device chassis
my %mhash; # hash for storing key-valiue pairs of module name - module id
my %links; # hash for storing links
my $dline = ""; #device line 
my $enmsNeIdName = ""; #some variable names
my $enmsNeType = "";
my $enmsNeLocation = "";
my $protocol = 1; # definition of protocol (e.g. detecting if we have ip defined or not)

# This part of script is parsing input file and creates hash with devices list 


#CREATING HASH WITH KEYVALUES FOR DEVICES
open(my $idfh, '<:encoding(UTF-8)', $inputDevicesFilename) #open file
    or die "Could not open file '$inputDevicesFilename' $!";


while (my $row = <$idfh>) { # read devices filename row by row
    next if $. < 4; # skip file headers (3 lines)
    chomp $row; # cut off last special character in a row
    my @words = split /$delimiter/, $row; #split row into array of strings 
    $enmsNeLocation = $words[3]; # get Netwrok Element location
    $enmsNeType = $words[1]; # add enmsNEType
    $enmsNeIdName = $words[12]; # add name of Network Element from enmsNeIdName (reason to use this is because it is fully populated with hostnmaes)

    # in this case we had extra file with set of management IP addresses. IP addresses were not written in SNMP tables,
    # IP ADDRESSES LOOKUP
    my $managementIP = $enmsNeIdName;
    my $enmsNeNEId = $words[0];
    open(IPFILE, "IP_Coriant.csv") or die "Can't find file";
    $protocol = 4;

    while(my $iprow = <IPFILE>) {
        chomp $iprow;
        my @ipwords = split /;/,$iprow;
        if ($enmsNeIdName eq $ipwords[0]) {
            $managementIP = $ipwords[2];
            $protocol = 1;
        }
          
    }
    close IPFILE;
    #END OF LOOKUP FOR IP ADDRESSES

    $dline = "$managementIP\|$protocol\|$enmsNeIdName\|.1.3.6.1.4.1.231.6.22.5.3\|\|$enmsNeIdName ($managementIP)\|1\|$enmsNeLocation\n"; #prepare line for csv file
    $ldevices{$enmsNeNEId} = $dline unless exists $ldevices{$enmsNeNEId}; #add hash with key set to $enmsNeNEId and value set to $dline line if such key does not exist
    $dhash{$enmsNeNEId} = $enmsNeIdName unless exists $dhash{$enmsNeNEId};
    #line has to follow device.csv pattern for perlCollector
    # ManagementIpAddress|Protocol|BaseName|SysObjectId|SysDescr|SysName|IpForwarding|ExtraInfo 
}

close $idfh;
#END OF CREATION OF HASH WITH KEYVALUES FOR DEVICES


#CREATION OF GENERIC ENTITES AS DESCRIBED IN PERL COLLECTOR EXAMPLES AKA POPULATING CHASSIES WITH MODULES
#-- genericentities.csv
#--
#-- Columns:
#--
#--     BaseName,EntityName,EntityType,EntityDescr,EntityParent,EntityRelPos,EntityHwRevision,EntitySwRevision,EntityFwRevision,EntitySerialNumber,CustomField
#--
#--     EntityType Enum : 0 - Other, 1 - Unknown, 2 - Chassis, 3 - Backplane, 4 - Slot, 5 - PSU, 6 - Fan, 7 - Sensor
#--                       8 - Module, 9 - Port, 10 - Rack
#--

open(my $modulesfh, '<:encoding(UTF-8)', $modulesFilename) # open file
    or die "Could not open file '$modulesFilename; $!";
while (my $row = <$modulesfh>) {
    next if $. < 4; #skip headers (3 lines)
    chomp ($row);
    my @words = split /$delimiter/, $row; #split rows int array of strings
    my $enmsMoNEId = $words[0]; # pick up device identifier
    my $BaseName = $dhash{$enmsMoNEId}; #get device name from hash
    my $enmsMoModuleId = $words[1];# pick up module identifier
    my $enmsMoName = $words[3]; #define position of module in chassis, backplane, whatever...
    if ($words[5] eq "") {
        $words[5] = "1"; #if position does not have a value we will consider it as a first module in chassis
    }
    my $enmsMoShelf = "Shelf - $words[5]"; #name the shelf (backplane)
    my $enmsMoSlot = "Slot - $words[6]"; #name the slot
    my $enmsMoObjectType = $words[7]; #find a tyoe
    my $name = "$BaseName|$enmsMoShelf|3|$enmsMoShelf|Coriant|$words[5]|NA|NA|NA|$enmsMoNEId|$enmsMoNEId\n"; 
    $lchassis{$name} = $enmsMoNEId unless exists $lchassis{$name};
    if ($enmsMoObjectType eq "1614") {
        $protocol = 6; #this is a Fan
    }
    elsif ($enmsMoObjectType eq "1402"){
        $protocol = 5; #this is a Power Supply
    }
    elsif ($enmsMoObjectType eq "8806"){
        $protocol = 6;#this is a Fan
    } 
    else {
        $protocol = 4;#rest are the slots
    }
    $name = "$BaseName|$enmsMoName|$protocol|$enmsMoName|$enmsMoShelf|$words[6]|NA|NA|NA|$enmsMoModuleId|NA\n"; #prepare line for csv fil
    $lchassis{$name} = $enmsMoNEId unless exists $lchassis{$name};#push line into the hash 
    my $mhashkey = "$enmsMoModuleId:$enmsMoNEId"; #create hash with key-values pairs for module names and module ids
    $mhash{$mhashkey} = $enmsMoName unless exists $mhash{$enmsMoModuleId};
}
close $modulesfh;


#CREATION OF GENERIC ENTITES
open(my $portfh, '<:encoding(UTF-8)', $portFilename) # open file
    or die "Could not open file '$portFilename; $!";
my $position = 1;
while (my $row = <$portfh>) {
    next if $. < 4; #skip headers (3 lines)
    chomp ($row);
    my @words = split /$delimiter/, $row; #split row into array of strings 
    my $enmsPtNEId = $words[0];#pick up varables
    my $enmsPtPortId = $words[1];
    my $enmsPtName = $words[2];
    my $enmsPtModuleId = $words[3];
    my $enmsPtInterfaceType = $words[6];
    my $enmsPtBandwidth = $words[7];
    my $BaseName = $dhash{$enmsPtNEId}; #get device name from hash
    my $hsearch = "$enmsPtModuleId:$enmsPtNEId";
    my $parent = $mhash{$hsearch}; #get module name from hash
    my $name = "$BaseName|$enmsPtName|9|$enmsPtName-$enmsPtInterfaceType-$enmsPtBandwidth|$parent|$enmsPtPortId|NA|NA|NA|NA\n"; #prepare line for csv file
    my $connhashkey = "$enmsPtNEId:$enmsPtPortId"; 
    $pint{$connhashkey} = $enmsPtName unless exists $pint{$connhashkey}; #push key-value pairs into hash
    $lchassis{$name} = $enmsPtModuleId unless exists $lchassis{$name};#push  line into hash
}
close $portfh;
#END OF CREATION OF GENERIC ENTITIES

#CREATION OF LINKS BETWEEND PORTS ON DEVICES 
#-- layer1Links.csv 
#-- 
#-- Columns:
#--      SourceName, SourceInterfaceId, DestinationName, DestinationInterfaceId, DestinationDirectionality
#--
#-- SourceName or DestinationName can be either in IP Address or
#-- deviceName.
#--


open(my $portconnfh, '<:encoding(UTF-8)', $portConnFilename) # open file
    or die "Could not open file '$portConnFilename; $!";
while (my $row = <$portconnfh>) {
    next if $. < 4; #skip headers (3 lines)
    chomp ($row);
    my @words = split /$delimiter/, $row; #split row into array of strings
    my $enmsPcSrcNEId = $words[1];
    my $enmsPcSrcPortId = $words[2];
    my $enmsPcDstNEId = $words[3];
    my $enmsPcDstPortId = $words[4];
    my $sourcehash = "$enmsPcSrcNEId:$enmsPcSrcPortId"; 
    my $desthash = "$enmsPcDstNEId:$enmsPcDstPortId";
    my $sourcename = $pint{$sourcehash};#get source port name from hash
    my $destname = $pint{$desthash};#get destination port  name from hash
    my $source = $dhash{$enmsPcSrcNEId};#get source device name from hash
    my $destination = $dhash{$enmsPcDstNEId};#get destination device name from hash
    my $name = "$source|$sourcename|$destination|$destname|1\n";#prepare line for CSV file
    $links{$name} = 1 unless exists $links{$name};

}
close $portconnfh;
#END OF CREATION OF LINKS

my $devices = 'devices.csv'; #open destination files
    open(my $fhdevices, '>>', $devices) or die "Could not open file '$devices' $!";

my $gdfilename = 'genericentities.csv';
    open(my $fhgd, '>>', $gdfilename) or die "Could not open file '$gdfilename' $!";
my $L1filename = 'layer1Links.csv';
    open(my $lfh, '>>', $L1filename) or die "Could not open file '$L1filename' $!";
foreach (sort values %ldevices) {  #print device to the output file
    print $fhdevices "$_";
}
foreach (sort keys %links) { #print links to the output file
    print $lfh "$_";
}
foreach (keys %lchassis) {  #print generic entites to the output file
    print  $fhgd "$_";
}
close $fhdevices;
close $fhgd;
close $lfh
