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

# Colours

my $unknowncolor = "#B2BEB5"; # Ash grey
my $okcolor = "#00ff00";
my $failcolor = "#ff0000";
my $progcolor = "#DDFF33";
my $prokcolor = "#19FFFF";
my $prfailcolor = "#FFB319";

my @Hosts;
my %Platforms;

my %target;
my %param;
my %hostos;
my %hostmach;
my %hostver;
my %hostbuilddate;


my %status;
my %oldbuild;
my %version;
my %date;
my %builddate;

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
	$param{$host} = "";
	$target{$host} = $scoop{'target'} if $scoop{'target'};
	$param{$host} = $scoop{'param'} if $scoop{'param'};
	$hostos{$host} = $scoop{'hostos'} if $scoop{'hostos'};
	$hostmach{$host} = $scoop{'hostmach'} if $scoop{'hostmach'};
	$hostver{$host} = $scoop{'hostver'} if $scoop{'hostver'};		
	$hostbuilddate{$host} = $scoop{'builddate'} if $scoop{'builddate'};		
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
		$status{$host}{$platform} = $scoop{'status'} if $scoop{'status'};
		$version{$host}{$platform} = $scoop{'version'} if $scoop{'version'};
		$builddate{$host}{$platform} = $scoop{'builddate'} if $scoop{'builddate'};
		$date{$host}{$platform} = $scoop{'date'} if $scoop{'date'};
		$oldbuild{$host}{$platform} = 0;
		$oldbuild{$host}{$platform} = 1	unless ($scoop{'version'} eq $target{$host});

		if ($hostbuilddate{$host} && $builddate{$host}{$platform}) {
			$oldbuild{$host}{$platform} = 1	unless ($hostbuilddate{$host} eq $builddate{$host}{$platform});
		}		
	}

}

my @Platforms = sort(keys(%Platforms));
@Hosts = sort(@Hosts);

my $_td="td align=\"center\"";

open OUT, ">$webresultsroot/index.html.new";

print OUT "<html>";
print OUT "<head><meta http-equiv=\"refresh\" content=\"600\"></head><body>";

print OUT "<h1 align=\"center\">NetBSD cross-building status</h1>\n";

print OUT "<table align=\"center\">";
print OUT "<tr><td><b>Key</b></td>";
print OUT "<td align=\"center\" bgcolor=\"$okcolor\">Success</td>";
print OUT "<td align=\"center\" bgcolor=\"$failcolor\">Failure</td>";
print OUT "<td align=\"center\" bgcolor=\"$prokcolor\">Success<br>(previously)</td>";
print OUT "<td align=\"center\" bgcolor=\"$prfailcolor\">Failure<br>(previously)</td>";
print OUT "<td align=\"center\" bgcolor=\"$progcolor\">In Progress</td>";
print OUT "<td align=\"center\" bgcolor=\"$unknowncolor\">Unknown</td>";
print OUT "</tr></table>";

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

print OUT "<tr><td></td>";
foreach my $host (@Hosts) {
	print OUT "<$_td>$param{$host}</td>";
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
			$color = $unknowncolor; # Ash grey
			$date = "";
			
			if (defined($status{$host}{$platform})) {
				
				$color = $okcolor if $status{$host}{$platform} eq 'OK';
				$color = $failcolor if $status{$host}{$platform} eq 'FAIL';
				$color = $progcolor if $status{$host}{$platform} eq 'PROG';

				if ($oldbuild{$host}{$platform}) {
					$color = $prokcolor if $status{$host}{$platform} eq 'OK'; 
					$color = $prfailcolor if $status{$host}{$platform} eq 'FAIL';
				}
				
				$date = $date{$host}{$platform} if ($date{$host}{$platform} &&
												$status{$host}{$platform} ne 'PROG');
				
				$date = "<em>Building</em>" if ($status{$host}{$platform} eq 'PROG');
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

my $dispdate = `date`;
print OUT "<center><em>Last updated $dispdate</em></center>\n";
print OUT "</body></html>\n";
close OUT;
system("mv $webresultsroot/index.html.new $webresultsroot/index.html");

# Failed builds list
#
