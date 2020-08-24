#!/usr/bin/perl -w

# Test shell script for subset-3
$num = 1;
if ($num > 0) {
	$num = $num + 3;
	print "$num\n";
}

if (-d '/2041/assign') {
	print "directory exist\n";
} else {
	print "directory NOT exist\n";
}

if (-d '/assign') {
	print "directory exist\n";
}

if (-d 'sheepl.pl') {
	print "file sheepl.pl exist\n";
} else {
	print "file not exist\n";
}

system "ls -las @ARGV";
exit 0;
