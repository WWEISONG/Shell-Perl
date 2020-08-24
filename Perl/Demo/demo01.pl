#!/usr/bin/perl -w

# demo shell script for subset-1

foreach $name ('Sherman', 'Adem', 'Amy', 'Allen') {
	print "hello you guys:\n";
	print "$name\n";
}

foreach $num (2000, 3000, 5000) {
	print "guess number, please input a number:\n";
	$number = <STDIN>;
	chomp $number;
	print "real number: $num\n";
	print "your number: $number\n";
}

foreach $word ('China', 2020, 'Great') {
	print "$word $word\n";
	exit 0;
}

foreach $word ('Houston', 1202, 'alarm') {
	print "$word\n";
}

foreach $word ('Houston', 1202, 'alarm') {
	print "$word\n";
	exit 0;
}

foreach $c_file (glob("*.c")) {
	print "gcc -c $c_file\n";
}
