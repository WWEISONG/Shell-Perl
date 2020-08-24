#!/usr/bin/perl -w

# Test shell script for subset-4
$i = 0;
$j = 1;
if ($i < 3 or $j > 5) {
	$i = $i + 1;
	$j = $j + 1;
	print "$i $j\n";
}

sub check_number {
	$num = $_[0];
	$i = 0;
	while ($i <= $num) {
		if ($i % 2 == 0) {
			print "$i is even\n";
		} else {
			print "$i is odd\n";
		}
		$i = $i + 1;
	}
}

&check_number(10);

print "Input a number between 1 to 4\n";
print "Your number is:\n";
$aNum = <STDIN>;
chomp $aNum;
if ($aNum =~ /1/) {
 	print "You select 1\n";
} elsif ($aNum =~ /2/) {
 	print "You select 2\n";
} elsif ($aNum =~ /3/) {
 	print "You select 3\n";
} elsif ($aNum =~ /4/) {
 	print "You select 4\n";
} else {
 	print "You do not select a number between 1 to 4\n";
}
