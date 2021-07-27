#!/usr/bin/perl
#
# Build a report on the web using the web output of buildwrapper.sh
#
# Provided as-is - if it breaks and no doubt it will, you get to keep
# the pieces.
#
# (c) Chris Pinnock 2021
#


use strict;
use warnings;

my $webresultsroot="/buildres"; 

my @Hosts;
my %Platforms;

my %target;
my %hostos;
my %hostmach;
my %hostver;

my %status;
my %version;
my %date;

# Open the directory. There is a directory for each host
#
opendir my $dh, "$webresultsroot" or die "Cannot open results directory\n";

HOST: while(my $host = readdir $dh) {
	next HOST if ($host eq '.' || $host eq '..');
	next HOST unless ( -d "$webresultsroot/$host" );
  
	# Get the host details
	#
	unless(open FILE, "$webresultsroot/$host/detail.txt") {
		warn "Cannot open details for $host\n";
		next HOST;
	}
	push @Hosts, $host;
	my %scoop;
	LINE: while(<FILE>) {
		chomp;
		my @a = split '\|';
			
		next LINE unless ((@a) == 2);
		
		$scoop{$a[0]} = $a[1];
	}
	close FILE;
	
	# Should really check that these are all set, but...
	#
	$target{$host} = $scoop{'target'} if $scoop{'target'};
	$hostos{$host} = $scoop{'hostos'} if $scoop{'hostos'};
	$hostmach{$host} = $scoop{'hostmach'} if $scoop{'hostmach'};
	$hostver{$host} = $scoop{'hostver'} if $scoop{'hostver'};		

	if ($hostver{$host} =~ m/\-/) {
		$hostver{$host} =~ s/\-.*$//;
	}


	my $hdh;
	unless(opendir $hdh, "$webresultsroot/$host/build") {
		warn "Cannot open host results directory for $host\n";
		next HOST;
	}
	PLATFORM: while(my $platform = readdir $hdh) {
		next PLATFORM if ($platform eq '.' || $platform eq '..');
		
		$Platforms{$platform} = 1;
		unless(open STATUS, "$webresultsroot/$host/build/$platform") {
			warn "Cannot open details for $host/$platform\n";
			next PLATFORM;
		}
		
		my %scoop;
		SLINE: while(<STATUS>) {
			chomp;
			my @a = split '\|';
			next SLINE unless ((@a) == 2);
			$scoop{$a[0]} = $a[1];
		}
		close STATUS;
		
		# These should be set normally...
		#
		
		$status{$host}{$platform} = 'UNKNOWN';
		if ($scoop{'version'} eq $target{$host}) {
				$status{$host}{$platform} = $scoop{'status'} if $scoop{'status'};
				$version{$host}{$platform} = $scoop{'version'} if $scoop{'version'};
				$date{$host}{$platform} = $scoop{'date'} if $scoop{'date'};
		}
		
	}

}

my @Platforms = sort(keys(%Platforms));
@Hosts = sort(@Hosts);

my $_td="td align=\"center\"";

open OUT, ">$webresultsroot/index.html.new";

print OUT "<html>";
print OUT "<head></head><body>";

print OUT "<table align=\"center\">";
# HEADINGS
#
print OUT "<tr><$_td></td>";
foreach my $host (@Hosts) {
	print OUT "<$_td>$host</td>";
}
print OUT "</tr>\n";

print OUT "<tr><$_td></td>";
foreach my $host (@Hosts) {
	print OUT "<$_td>$hostos{$host}/$hostmach{$host}</td>";
}
print OUT "</tr>\n";

print OUT "<tr><td></td>";
foreach my $host (@Hosts) {
	print OUT "<$_td>$hostver{$host}</td>";
}
print OUT "</tr>\n";

print OUT "<tr><td> </td></tr>\n";

print OUT "<tr><td><em>Building</em></td>";
foreach my $host (@Hosts) {
	print OUT "<$_td>$target{$host}</td>";
}
print OUT "</tr>\n";
print OUT "<tr><td> </td></tr>\n";

foreach my $platform (@Platforms) {
		
		print OUT "<tr>";
		print OUT "<td>$platform</td>";
		foreach my $host (@Hosts) {
			
			my $date = "";
			my $link = "";
			
			my $color;
			
			# Defaults
			$color = "#B2BEB5"; # Ash grey
			$date = "-";
			
			if (defined($status{$host}{$platform})) {
				
				$color = "#00ff00" if $status{$host}{$platform} eq 'OK';
				$color = "#ff0000" if $status{$host}{$platform} eq 'FAIL';
				$color = "#DDFF33" if $status{$host}{$platform} eq 'PROG';
				
				$date = $date{$host}{$platform} if ($date{$host}{$platform} &&
												$status{$host}{$platform} ne 'PROG');
												
				$link = "$host/logs/$platform-tail.txt" if $status{$host}{$platform} eq 'FAIL';
			}
			
			print OUT "<td align=\"center\" bgcolor=\"$color\">";
			print OUT "<a href=\"$link\">" if $link;
			print OUT "$date";
			print OUT "</a>" if $link;
			print OUT "</td>";
		}
		
		print OUT "</tr>\n";

}

print OUT "</table>";
print OUT "</body></html>\n";
close OUT;
system("mv $webresultsroot/index.html.new $webresultsroot/index.html");
