#!/usr/bin/perl -w

# test 'test' expression and backticks
$i = 1;
$j = 10;

if ($i < 5  and $j > 3 ) {
	$i = $i + 1;
	# expression with backticks  
	$i = $i + 1;
	print "$i\n";
}
