#!/usr/bin/perl -w

# Test if statements with composite conditions
$i = 1;
$j = 10;

if ($i < 5 and $j > 3) {
	$i = $i + 1;
	print "$i\n";
}
