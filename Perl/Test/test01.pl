#!/usr/bin/perl -w

# Test for while loop with composite conditions
$i = 0;
$j = 1;
while ($i < 100 and $j <= 30) {
	print "$i $j\n";
	$i = $i + 1;
}
