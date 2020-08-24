#!/usr/bin/perl -w

# Test function declaration and function call
sub say_hello {
	my ($i);
	$i = $_[0];
	while ($i < 3) {
		print "hello there!!\n";
		$i = $i + 1;
	}
}

&say_hello(2);
