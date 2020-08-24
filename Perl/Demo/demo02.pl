#!/usr/bin/perl -w

# Test shell script for subset-2
if ('name' eq 'Sam') {
	print "hello Sam\n";
} elsif ('name' eq 'Sherman') {
	print "hello Sherman\n";
} elsif ('name' eq 'Will') {
	print "hello Will\n";
}

if ('name' eq 'name' and 'family' eq 'family') {
	print "not possible\n";
}

if ('Andrew' eq 'great') {
	print "correct\n";
} elsif ('Andrew' eq 'fantastic') {
	print "yes\n";
} else {
	print "error\n";
}

$i = 0;
$j = 10;
if ($i < 30 and $j <= 10) {
	print "success\n";
}
