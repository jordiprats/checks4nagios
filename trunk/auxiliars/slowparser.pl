#!/usr/bin/perl

# Time: 100103  0:01:09
# User@Host: comunidades[comunidades] @  [10.12.50.129]
# Query_time: 2.006015  Lock_time: 0.000029 Rows_sent: 1  Rows_examined: 1


my $data="";
my $hora="";
my $luser="";
my $host="";

my $querytime="";
my $locktime="";

my %totalslows_ahir;
my %totaltemps_ahir;
my %tempslock_ahir;

my %totalslows_avansahir;
my %totaltemps_avansahir;
my %tempslock_avansahir;

my %totalslows_setmanapasada;
my %totaltemps_setmanapasada;
my %tempslock_setmanapasada;


my $ahir = time - 24 * 60 * 60;
($day, $month, $year) = (localtime($ahir))[3,4,5];
$year-=100;
$month++;
$stringahir=sprintf("%02d%02d%02d",$year,$month,$day);

my $avansahir = time - 2 * 24 * 60 * 60;
($day, $month, $year) = (localtime($avansahir))[3,4,5];
$year-=100;
$month++;
$stringavansahir=sprintf("%02d%02d%02d",$year,$month,$day);

my $setmanapasada = time - 7 * 24 * 60 * 60;
($day, $month, $year) = (localtime($setmanapasada))[3,4,5];
$year-=100;
$month++;
$stringsetmanapasada=sprintf("%02d%02d%02d",$year,$month,$day);

while ($line = <>) 
{
    	#print "LINE:".$line;

	if($line =~ m/^# Time:\s+(\d+)\s+(\d+:\d+:\d+)/i)
	{	
		#print "LOL time - date: $1 - hora: $2\n";
	
		$data=$1; $hora=$2;
	}
	
	if($line =~ m/^# User\@Host:\s+(\w+)\[?\w*\]?\s+\@\s+\[?([\w\.]+)\]?/i)
	{
		#print "LOL2 USER: $1 -- Host: $2\n";
	
		$luser=$1; $host=$2;
	}	

	if($line =~ m/^# Query_time:\s+([\d\.]+)\s+Lock_time:\s+([\d\.]+)\s+Rows_sent:\s+([\d\.]+)\s+Rows_examined:\s+([\d\.]+)/i)
	{
		#print "LOL3 $1 $2 $3 $4\n";
		
		if($data eq $stringahir)
		{	
			$totalslows_ahir{$luser}++;		
			$totaltemps_ahir{$luser}+=$1;		
			$tempslock_ahir{$luser}+=$2;	
		
		}

		if($data eq $stringsetmanapasada)
		{
			$totalslows_setmanapasada{$luser}++;		
			$totaltemps_setmanapasada{$luser}+=$1;		
			$tempslock_setmanapasada{$luser}+=$2;	
		}

		if($data eq $stringavansahir)
		{
			$totalslows_avansahir{$luser}++;		
			$totaltemps_avansahir{$luser}+=$1;		
			$tempslock_avansahir{$luser}+=$2;	
		}
	}
}

#print "============= total slows ================\n";
while ( my ($key, $value) = each(%totalslows_ahir) )
{
        #print "$key => ahir: $value avans ahir: $totalslows_avansahir{$key} setmana pasada: $totalslows_setmanapasada{$key}\n";
	print "ALERTA -  l'usuari $key ha doblat el nombre de slowqueries (ahir: $value avans ahir: $totalslows_avansahir{$key} setmana pasada: $totalslows_setmanapasada{$key}\n" if (($value>$totalslows_avansahir{$key}*2)&&($value>$totalslows_setmanapasada{$key}*2));
	print "WARNING -  l'usuari $key ha doblat el nombre de slowqueries (ahir: $value avans ahir: $totalslows_avansahir{$key} setmana pasada: $totalslows_setmanapasada{$key}\n" if (($value>$totalslows_avansahir{$key}*2)||($value>$totalslows_setmanapasada{$key}*2));
}

#print "============= total temps ================\n";
while ( my ($key, $value) = each(%totaltemps_ahir) )
{
        #print "$key => ahir: $value avans ahir: $totaltemps_avansahir{$key} setmana pasada: $totaltemps_setmanapasada{$key}\n";
	print "ALERTA -  l'usuari $key ha doblat el total de temps passat en slowqueries (ahir: $value avans ahir: $totaltemps_avansahir{$key} setmana pasada: $totaltemps_setmanapasada{$key}\n" if (($value>$totaltemps_avansahir{$key}*2)&&($value>$totaltemps_setmanapasada{$key}*2));
	print "WARNING -  l'usuari $key ha doblat el total de temps passat en slowqueries (ahir: $value avans ahir: $totaltemps_avansahir{$key} setmana pasada: $totaltemps_setmanapasada{$key}\n" if (($value>$totaltemps_avansahir{$key}*2)||($value>$totaltemps_setmanapasada{$key}*2));
}

#print "============= total lock ================\n";
while ( my ($key, $value) = each(%tempslock_ahir) )
{
        #print "$key => ahir: $value avans ahir: $tempslock_avansahir{$key} setmana pasada: $tempslock_setmanapasada{$key}\n";
	print "ALERTA -  l'usuari $key ha doblat el temps pasat en locks (ahir: $value avans ahir: $tempslock_avansahir{$key} setmana pasada: $tempslock_setmanapasada{$key}\n" if (($value>$tempslock_avansahir{$key}*2)&&($value>$tempslock_setmanapasada{$key}*2));
	print "WARNING -  l'usuari $key ha doblat el temps pasat en locks (ahir: $value avans ahir: $tempslock_avansahir{$key} setmana pasada: $tempslock_setmanapasada{$key}\n" if (($value>$tempslock_avansahir{$key}*2)||($value>$tempslock_setmanapasada{$key}*2));
}




