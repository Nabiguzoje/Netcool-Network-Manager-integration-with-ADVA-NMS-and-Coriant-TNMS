#!/usr/bin/perl
use strict;
use warnings;
    
#definicja varijabli
my %ldevices; # hash u kojem se drze uredjai
my %lchassis; # hash sa definicijama sasija uredjaja
my $dlinija = ""; # varijabla koja sadzri vrijednos koja se upisuje u hash za uredjaje
my $clinija = ""; # varijabla koja sadrzi vrijednost koja se upisiju u hash za sasije
my $inventoryfilename = '/opt/IBM/netcool/core/precision/collectors/perlCollectors/Csv/DataFiles/NetworkInventory.csv'; #hardkodirano ime datoteke sa inventarom
my $devicesfilename = '/opt/IBM/netcool/core/precision/collectors/perlCollectors/Csv/DataFiles/devices.csv'; #hardkodirano ime datotke za ispsi hasha
my $topologyfilename = '/opt/IBM/netcool/core/precision/collectors/perlCollectors/Csv/DataFiles/TopologyReport.csv'; #harkodirano ime datoteke sa topologijom
my $linksfilename = '/opt/IBM/netcool/core/precision/collectors/perlCollectors/Csv/DataFiles/layer1Links.csv'; #harkodirano ime sa layer1 linkovima
my $elementsfilename = '/opt/IBM/netcool/core/precision/collectors/perlCollectors/Csv/DataFiles/genericentities.csv'; #harkodirano ime sa entitietima
my @words = ""; #  niz strigova u koji ce se upisivati vrijednost iz datoteke
my @name = ""; # pomocna varijabla za unos imena uredjaja
my $ip_address = ""; # varijabla za unos ip adrese uredjaja
my $devicename = ""; # vatijabla za unos imena uredjaja 
my @position = ""; #niz koji odredjue poziciju elemnta na uredjaju
my $hostname = ""; #pomocna varijabla koja nam sluzi za prvjeru da li element pripada istom uredjaju
my $dposition = 0; #pozicija elementa
my $shelfname = "";#ime shelfa
my $sposition = 0;#pozicija elementa
my $type = 0;#tip elementa
my %pairs = ();

    
open(my $fh, '<', $inventoryfilename)
    or die "Could not open file '$inventoryfilename' $!"; #  datoteku sa inventarom otvori za citanje
open(my $fhdevices, '>', $devicesfilename) 
    or die "Could not open file '$devicesfilename' $!"; # datoteku za upis uredjaja otvori za pisanje
open(my $fhgenericentities, '>', $elementsfilename) or die "Could not open file '$elementsfilename' $!";
while (my $row = <$fh>) { #citaj datoteku sa inventarom red po red
    chomp $row; #odbaci zadnji specijalni karakter iz linije datoeke (koji postoji u orginalnoj datoteci)
    @words = split /;/, $row; #razbij ucitani red u niz (delimiter niza je znak | )
    @name = split /\(/, $words[1]; # prvi element niza sadrzi ime uredjaja, ali takodjer sadzi i ip adresu unutar oblih zagrada
    #print"@name/n";
    $ip_address = $words[37]; #uzmi IP adresu
    $devicename = $words[1]; #uzmi ime 
    if ($name[1] ne "") {
        chop $name[1];
        chop $name[0];
        $pairs{$name[0]} = $name[1] unless exists $pairs{$name[0]};
    }
    #chop $ip_address; #odbaci razmak koji je ostao u ip_adresi
    if ($words[4] eq "") { #uzmi linije koje nemaju ime modula u sebi
        if ($words[25] =~ m/SHELF/) { # uzmi linije koje imaju definiciju shelf-a u sebi
            my @position = split /-/, $words[25]; # uzmi broj selfova radi pozicioniranja unutar definicije uredjaja
            $clinija =  "$devicename|$words[25]|4|$words[25] $words[22]|$words[2]|$position[1]|$words[23]|N\/A|N\/A|$words[24]|$words[29]\n"; # kreiraj zapis za elemente unutar uredjaja
            $lchassis{$clinija} = 1 unless exists $lchassis{$clinija}; #ubaci elemente u hash
        }
        $dlinija = "$ip_address\|1\|$devicename\|1.3.6.1.4.1.2544.1.11.1\|\|$devicename\|1\|region\n" unless $. == 1; #kreiraj zapis sa uredjajem 
        $ldevices{$dlinija} = 1 unless exists $ldevices{$dlinija}; # ukoliko zapis ne postoji u hash-u onda ga ubaci u hash
    }
    else {
        if ($words[25] =~ m/PSH/){ # provjeri da li je to pasivni element
            if ($hostname eq $devicename) { #da li je to prvi pasivni element na uredjaju?
                $dposition = $dposition + 1; #ako nije povecaj poziciju
            }
            else {
                $dposition = 1; #ako je onda vrati pozciju na 1
                $hostname = $devicename; #i ubaci u pomocu varijablu ime elementa koji se trenutno obradjuje
            }
            $clinija =  "$devicename|$words[4]|0|$words[5]|$words[2]|$dposition|$words[12]|$words[14]|$words[13]|$words[15]|$words[16]\n"; #kreiraj zapis o pasivnom elementu
            $lchassis{$clinija} = 1 unless exists $lchassis{$clinija}; #dodaj ga u hash i pazi na duple elemente
        }
        elsif ($words[25] =~ m/SHELF/ && $words[4] !~ m/PL\-/) { #provjeri da li se radi o elementu unutar shelfa
            if ($shelfname eq $devicename) { #da li je to prvi pasivni element na uredjaju?
                $sposition = $sposition + 1; #ako nije povecaj poziciju
            }
            else {
                $sposition = 1; #ako je onda vrati pozciju na 1
                $shelfname = $devicename; #i ubaci u pomocu varijablu ime elementa koji se trenutno obradjuje
            }
            if ($words[4] =~ m/FCU/) { # provjeri da li se radi o ventilatoru
                $type = 6; #postavi tip uredjaja na ventilator
                $clinija =  "$devicename|$words[4]|$type|$words[5]|$words[25]|$sposition|$words[12]|$words[14]|$words[13]|$words[15]|$words[16]\n"; # kreiraj zapisa za hash
            }
            else { #znaci radi se o modulu
                my @slot = split /-/, $words[4]; #uzmi broj slota
                $type = 8; #postavi tip uredjaja na modul
                $clinija =  "$devicename|$words[4]|$type|Slot $slot[2]-$words[5]|$words[25]|$sposition|$words[12]|$words[14]|$words[13]|$words[15]|$words[16]\n"; #kreiraj zapis za hash
           }
           $lchassis{$clinija} = 1 unless exists $lchassis{$clinija}; #dodaj zapis na hash ako vec takav zapis ne postoji
       }

    }
}


open(my $fhtopology, '<', $topologyfilename)
    or die "Could not open file '$topologyfilename' $!"; #  datoteku sa inventarom otvori za citanje
open(my $fhlinks, '>', $linksfilename) 
    or die "Could not open file '$linksfilename' $!"; #  datoteku sa inventarom otvori za citanje


my $llinija = "";  # deklaracija varijabli
my %links;
my $olinija = "";
my %ohash;
my $oposition = 1110;
my @oarray = "";
my $skipline = <$fhtopology>; #preskoci prvu liniju u fajli
while (my $row2 = <$fhtopology>){
    chomp $row2;
    $oposition = 1110; #postavi inicijalnu poziciju za portove
    @words = split /;/, $row2;
    $llinija = "$words[0] ($pairs{$words[0]})|$words[1]|$words[2] ($pairs{$words[2]})|$words[3]|1\n"; #kreiraj linkove
    $links{$llinija} = 1 unless exists $links{$llinija}; #ubaci linkove u link hash
    $olinija = "$words[0] ($pairs{$words[0]})|OL Shelf|4|OL Shelf|FSP 3000R7|11|N/A|N/A|N/A|N/A|Assigned\n"; #kreiraj extra shelf za linkove na osnovu izlaznog porta
    $lchassis{$olinija} = 1 unless exists $lchassis{$olinija}; #ubaci u hash
    $olinija = "$words[2] ($pairs{$words[2]})|OL Shelf|4|OL Shelf|FSP 3000R7|11|N/A|N/A|N/A|N/A|Assigned\n"; #kreiraj exstra shelf za linove na osnovu destinacijskog porta
    $lchassis{$olinija} = 1 unless exists $lchassis{$olinija}; #ubaci u hash
    $olinija = "$words[0] ($pairs{$words[0]})|Optical Lines|8|Optical Lines|OL Shelf|111|N/A|N/A|N/A|N/A|Assigned\n"; #krairaj modul za liknove na osnovu izlazlnog porta
    $lchassis{$olinija} = 1 unless exists $lchassis{$olinija}; #ubaci u hash
    $olinija = "$words[2] ($pairs{$words[2]})|Optical Lines|8|Optical Lines|OL Shelf|111|N/A|N/A|N/A|N/A|Assigned\n"; #krairaj modul za liknove na osnovu destinacijskog porta
    $lchassis{$olinija} = 1 unless exists $lchassis{$olinija}; #ubaci u hash
    @oarray = split /-/, $words[1];
    my $cposition = $oposition + $oarray[1]; #izracunaj poziciju u modulu na osnovu broaj linka
    $olinija = "$words[0] ($pairs{$words[0]})|$words[1]|9|$words[1]|Optical Lines|$cposition|N/A|N/A|N/A|N/A|N/A\n"; #kreiraj port na osnovi izlaznog porta
    $lchassis{$olinija} = 1 unless exists $lchassis{$olinija}; #ubaci u hash
    @oarray = split /-/, $words[3];
    $cposition = $oposition + $oarray[1]; ##izracunaj poziciju u modulu na osnovu broaj linka
    $olinija = "$words[2] ($pairs{$words[2]})|$words[3]|9|$words[3]|Optical Lines|$cposition|N/A|/N/A|N/A|N/A|N/A\n"; #kreiraj port na osnovi destinacijskog porta
    $lchassis{$olinija} = 1 unless exists $lchassis{$olinija}; #ubaci u hash
}


foreach (sort keys %links) { #sortiraj i ispisi linkove u fajl
    printf $fhlinks "$_";
}
foreach (sort keys %ldevices) { # abecedno sortiraj hash i ispisi ga u datoteku
    printf $fhdevices "$_";
}
foreach (sort keys %lchassis) { # abecedno sortiraj hash i ispisi ga u datoteku
   printf $fhgenericentities  "$_";
   #printf "$_";
}
close $fh; #zatvori datoteke
close $fhdevices;
close $fhgenericentities;
close $fhlinks;

