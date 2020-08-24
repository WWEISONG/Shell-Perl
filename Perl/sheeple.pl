#!/usr/bin/perl -w

# According to compiler principle, first step is finding the grammer of
# shell script language, as my perspective there are totally two modulers
# of shell script which inculding functions and command expressions. As
# we only need to consider some subset of the whole shell script, below
# are the grammers for the subset of shell scipt:

# shell_program -> expr*
#               -> (function|expr)*

# function      -> signature() { expr* }

# expr          -> echo
#               -> ls
#               -> pwd
#               -> cd
#               -> id
#               -> date
#               -> rm
#               -> exit
#               -> chmod
#               -> mv
#               -> test
#               -> return
#               -> assign 
#               -> for
#               -> if
#               -> condition
#               -> case
#               -> while
#               -> func_call
#               -> expr_expr 
#               -> read 
#               -> comment 

# echo          -> echo (word|variable)*
#               -> echo "(word|variable)*"
#               -> echo '(word|variable)*'
# ls            -> ls PATH?
# pwd           -> pwd
# cd            -> cd PATH
# id            -> id
# date          -> date
# rm            -> FLAGS variables
# exit          -> exit [0|1]
# chmod_expr    -> chmod [0-9]{3} variables 
# test          -> test -d PATH 
#               -> test parameter -lt|-le|-eq|-gt|-ge parameter 
#               -> test composite
# condition_expr-> [ condition ] ((&&|\|\|) [ condition ])*
# mv_expr       -> FLAGS [variable] [variable]
# while         -> condition | test { compound exprs }
# condition     -> [ condition ] [ logic operators ] [ condition ]*
# func_call     -> signature args
# read          -> read variable
# comment       -> # words
# if            -> if condition do if_compound done

# Thus, according to the grammer we can parse the function and the expr one by one
# And also I use level to indicate the level of the current command and to decide
# how many indentation should put before this command. So after get the data from
# STDIN I will split them as separate word, which is also know as token in compiler
# principle. Then read token one by one and according to the token to confirm the 
# following expressions, for example, if current token is 'echo' then I can think
# the following tokens belong to echo expresion until we meet the token including 
# the '\n' at the end.

# -- Wei Song, z5198433


# ------------------------ Pre processing ------------------------ #
# read data from stdin and split the whole data into single word and
# put them into a container-tokens which is a global variable.

sub pre_processing {
	if (@ARGV != 0) {
		open(FILE, '<', "$ARGV[0]") or die "Cannot open file $ARGV[0]: $!\n";
		@shell_script = <FILE>;
	} else {
		@shell_script = <>;
	}

	shift(@shell_script);

	foreach $line (@shell_script) {
		$line =~ s/^ *//;
		$line =~ s/^\t*//;
		push @tokens, split(/ /, $line);
	}

	print("#!/usr/bin/perl -w\n");
}

# ------------------------ Parse-Shell program -------------------- #
# Shell program is composed of two parts: functions and expressions
# Enter parse_shell --> parse_func
#                   --> parse_exprs
sub parse_shell {
	&pre_processing;
	for ($token_pos = 0; $token_pos < @tokens; $token_pos++) {
		$token = $tokens[$token_pos];
		if ($token =~ m/^ *$|^( |\n)*$/) {
			print "\n";
			next;
		}
		$global_variable = 1;
		$level = 0;
		if ($token =~ /\(\)$/ && $tokens[$token_pos+1] =~ /\{\n$/) {
			&parse_func($global_variable, $level);
		} else {
			&parse_exprs($global_variable, $level);
		}
	}
}

# -------------------------- Parse-Functions ---------------------- #
# Functions are composed of function signature() { function exprs }
# Inside function, the variables should be local variables and take
# the level into the expresion of the function to indicate indentation
sub parse_func {
	my $global_variable = 0;
	my $level = $_[1];
	$token =~ s/\(\)//;
	&print_level_to_tab($level);
	print("sub $token {\n");
	&move_to_next_token;
	&move_to_next_token;
	$level = $level + 1;
	while ($token !~ /^\}\n$/) {
		&parse_exprs($global_variable, $level);
		&move_to_next_token;
	}
	&print_level_to_tab;
	print("}\n");
}

# -------------------------- Parse-Expresions ---------------------- #
# For expresions, there are many cases need to consider. Try to match
# each case by the first token, and enter the related cases. So every
# loop will parse one expresion until meet the terminal of the expresion

# And the global_variable is trying to indicate if the variable is global
# or not, and level is trying to indicate the indentation for expression.
sub parse_exprs {
	my $global_variable = $_[0];
	my $level = $_[1];

	if ($token =~ /echo/) {
		&parse_echo($global_variable, $level);
	} 
	elsif ($token =~ /^ls$/) {
		&parse_ls($global_variable, $level);
	} elsif ($token =~ /^pwd$/) {
		&parse_pwd($global_variable, $level);
	} elsif ($token =~ /^cd$/) {
		&parse_cd($global_variable, $level);
	} elsif ($token =~ /^id$/) {
		&parse_id($global_variable, $level);
	} elsif ($token =~ /^date$/) {
		&parse_date($global_variable, $level);
	} elsif ($token =~ /^rm$/) {
		&parse_rm($global_variable, $level);
	} elsif ($token =~ /^exit$/) {
		&parse_exit($global_variable, $level);
	} elsif ($token =~ /^chmod$/) {
		&parse_chmod($global_variable, $level);
	} elsif ($token =~ /^mv$/) {
		&parse_mv($global_variable, $level);
	} elsif ($token =~ /^test/) {
		&parse_test($global_variable, $level);
	} elsif ($token =~ /^return/) {
		&parse_return($global_variable, $level);
	} elsif ($token =~ /.*=.*/) {
		&parse_assign($global_variable, $level);
	} elsif ($token =~ /^for/) {
		&parse_for($global_variable, $level);
	} elsif ($token =~ /^if$/) {
		&parse_if($global_variable, $level);
	} elsif ($token =~ /^while/) {
		&parse_while($global_variable, $level);
	} elsif ($token =~ /^case/) {
		&parse_case($global_variable, $level);
	} elsif ($token =~ /^ +$/ || $token =~ /^\n+$/) {
		print("\n");
	} elsif ($token =~ /local/) {
		&parse_local($global_variable, $level);
	} elsif ($token =~ /^read/) {
		&parse_read($global_variable, $level);
	} elsif ($token =~ /^#/) {
		&parse_comment($global_variable, $level);
	} elsif ($token =~ /^\`/) {
		&parse_expr_expr($global_variable, $level);
	}
	else {
		&parse_func_call($global_variable, $level);
	}
}

# ---------------------------- Parse-echo -------------------------- #
# For echo there are four cases need to consider:
# 1. normal echo, just echo and followed by some words and variables
# 2. normal echo with quotes, double quotes or single quotes or both
# 3. special operation in echo expresion like write file with > or >>
# 4. echo with some special variables like $1, $2, $3...
sub parse_echo {
	my $global_variable = $_[0];
	my $level = $_[1];
	&move_to_next_token;

	my $new_line = 1;
	if ($token =~ /^-n$/) {
		$new_line = 0;
		&move_to_next_token;
	}

	if ($token =~ /^[\"\']/) {
		$token =~ s/[\"\']//;
		if ($token =~ /[\"\']\n/) {
			$token =~ s/[\"\']\n/\n/;
		}
		my $end_echo_pos = $token_pos;
		while ($tokens[$end_echo_pos] !~ /\n$/) {
			$end_echo_pos += 1;
		}
		if ($tokens[$end_echo_pos] =~ /^\n$/) {
			$end_echo_pos = $end_echo_pos - 1;
		}
		$tokens[$end_echo_pos] =~ s/[\"\']//;
	}

	my $end_pos = $token_pos;
	while ($tokens[$end_pos] !~ /\n$/) {
		$end_pos = $end_pos + 1;
	}

	if ($tokens[$end_pos] =~ /^\n$/) {
		$end_pos = $end_pos - 1;
	}

	if ($tokens[$end_pos] =~ /^\>\>/ || $tokens[$end_pos] =~ /^\>/) {
		&parse_write_file($end_pos, $level, $global_variable, $new_line);
	} else {
		&print_level_to_tab($level);
		print("print \"");
		while ($token !~ /\n$/) {
			&parse_echo_cases($global_variable);
			if ($tokens[$token_pos+1] !~ /^\n$/) {
				print(" ");
			}
			&move_to_next_token;
		}

		if ($token !~ /^\n$/) {
			$token =~ s/\n//;
			&parse_echo_cases($global_variable);
		}

		if ($new_line == 1) {
			print("\\n\";\n");	
		} else {
			print("\";\n");
		}
	}
}

# ----------------------- Parse-system commands -------------------- #
# system command includs ls, pwd, date, id, which these commands will be
# directly translated as ststem "command" in perl. 
sub parse_ls {
	my $global_variable = $_[0];
	my $level = $_[1];
	&print_level_to_tab($level);
	if ($token =~ /\n$/) {
		print("system \"ls");
		print("\";\n");
	} else {
		print("system \"ls ");
		&move_to_next_token;
		while ($token !~ /\n$/) {
			&parse_variable($global_variable);
			print(" ");
			&move_to_next_token;
		} 
		$token =~ s/\n//;
		&parse_variable($global_variable);
		print("\";\n");
	}
}

sub parse_pwd {
	my $global_variable = $_[0];
	my $level = $_[1];
	&print_level_to_tab($level);
	print("system \"pwd\";\n");
}

sub parse_id {
	my $global_variable = $_[0];
	my $level = $_[1];
	&print_level_to_tab($level);
	print("system \"id\";\n");
}

sub parse_date {
	my $global_variable = $_[0];
	my $level = $_[1];
	&print_level_to_tab($level);
	print("system \"date\";\n");
}

sub parse_cd {
	my $global_variable = $_[0];
	my $level = $_[1];
	&print_level_to_tab($level);
	print("chdir \'");
	&move_to_next_token;
	$token =~ s/\n//;
	&parse_variable($global_variable);
	print("\';\n");
}

sub parse_rm {
	my $global_variable = $_[0];
	my $level = $_[1];
	&print_level_to_tab($level);
	print "system \"rm ";
	&move_to_next_token;
	while ($token !~ m/\n$/) {
		&parse_variable($global_variable);
		print " ";
		&move_to_next_token;
	}
	$token =~ s/\n//;
	&parse_variable($global_variable);
	print "\";\n";
}

sub parse_exit {
	my $global_variable = $_[0];
	my $level = $_[1];
	&print_level_to_tab($level);
	print "exit ";
	&move_to_next_token;
	$token =~ s/\n//;
	print "$token;\n";
}

sub parse_chmod {
	my $global_variable = $_[0];
	my $level = $_[1];
	&print_level_to_tab($level);
	print "system \"chmod ";
	&move_to_next_token;
	while ($token !~ m/\n$/) {
		&parse_variable($global_variable);
		print " ";
		&move_to_next_token;
	}
	$token =~ s/\n//;
	&parse_variable($global_variable);
	print "\";\n";
}

sub parse_mv {
	my $global_variable = $_[0];
	my $level = $_[1];
	&print_level_to_tab($level);
	print "system \"mv ";
	&move_to_next_token;
	while ($token !~ m/\n$/) {
		&parse_variable($global_variable);
		print " ";
		&move_to_next_token;
	}
	$token =~ s/\n//;
	&parse_variable($global_variable);
	print "\";\n";
}

# ---------------------------- Parse-test -------------------------- #
# test expresion has same effects as [], for test there are two cases:
# 1. normal test start with test and variables and the logic operators
# 2. composite test with -a,-o, or start with !, which is complex
sub parse_test {
	my $global_variable = $_[0];
	my $level = $_[1];
	&move_to_next_token;
	if ($global_variable == 0 && $tokens[$token_pos-2] !~ m/(while|if|for)/) {
		&print_level_to_tab($level);
	}
	&parse_test_parameter($global_variable);
	print " ";
	&move_to_next_token;
	if ($tokens[$token_pos-1] =~ /^-[a-zA-Z]/) {
		&parse_test_parameter($global_variable);
		&move_to_next_token;
	} else {
		if ($token !~ m/\n$/) {
			&parse_test_operator;
			print " ";
			&move_to_next_token;
		}
		&parse_test_parameter($global_variable);
		&move_to_next_token;
	}
	if ($token =~ m/(&&|\|\|)/) {
		print " ";
		&parse_logic_operators;
		print " ";
		if ($tokens[$token_pos+1] =~ /test/) {
			&move_to_next_token;
			&move_to_next_token;
			&parse_test_nest($global_variable);
		} elsif ($tokens[$token_pos+1] =~ /\[/) {
			&move_to_next_token;
			&move_to_next_token;
			&parse_condition_nest($global_variable);
		} 
	} elsif ($token =~ /(!|-o|-a)/) {
		&parse_bool_operators;
		&move_to_next_token;
		&parse_test_nest($global_variable);
	}
}

# ---------------------------- Parse-condition -------------------------- #
# condition is same as test but using [], for condition there are two cases:
# 1. normal condition, put the condition into [] and with logic operators
# 2. composite conditions with several [], [ condition ] && [ conditoin ]..
sub parse_condition {
	my $global_variable = $_[0];
	my $level = $_[1];
	&move_to_next_token;
	if ($global_variable == 0 && $tokens[$token_pos-2] !~ m/(while|if|for)/) {
		&print_level_to_tab($level);
	}
	&parse_test_parameter($global_variable);
	print " ";
	&move_to_next_token;
	if ($tokens[$token_pos+1] =~ /\]/) {
		&parse_test_parameter;
		&move_to_next_token;
		&move_to_next_token;
	} else {
		if ($token !~ m/\n$/) {
			&parse_test_operator;
			print " ";
			&move_to_next_token;
		}
		&parse_test_parameter($global_variable);
		&move_to_next_token;
		&move_to_next_token;
	}

	if ($token =~ m/&&|\|\|/) {
		print " ";
		&parse_logic_operators;
		print " ";
		if ($tokens[$token_pos+1] =~ /test/) {
			&move_to_next_token;
			&move_to_next_token;
			&parse_test_nest($global_variable);
		} elsif ($tokens[$token_pos+1] =~ /\[/) {
			&move_to_next_token;
			&move_to_next_token;
			&parse_condition_nest($global_variable);
		}
	}
}

sub parse_return {
	my $global_variable = $_[0];
	my $level = $_[1];
	if ($global_variable == 0 && $tokens[$token_pos-1] !~ m/(&&|\|\|)/) {
		&print_level_to_tab($level);
	}
	print "return ";
	&move_to_next_token;
	$token =~ s/\n//;
	print "$token;\n";
}

# ---------------------------- Parse-assign -------------------------- #
# For assign expression, there are two cases need to consider
# 1. use backticks: for example number=`expr $number + 1`
# 2. use dollar and brackets: for example number=$((number +1))
sub parse_assign {
	my $global_variable = $_[0];
	my $level = $_[1];
	&print_level_to_tab($level);
	$token =~ s/\n//;
	@assign_list = split(/=/, $token);
	$assign_list[0] =~ s/[ \t]*//;
	print "\$$assign_list[0]";
	print " = ";
	$token = $assign_list[1];
	if ($token !~ /^\`expr/ && $token !~ /^\$\(expr/) {
		&parse_test_parameter;
	} else {
		&parse_expr_expr($global_variable, $level);
	}
	print ";\n";
}

# ---------------------------- Parse-while -------------------------- #
# while expression, according to the grammer it's easy to parse
# first step is to find the while conditions, and second step
# step is to find the compound expression inside while and pass 
# the parameter args into the while compound expression.
sub parse_while {
	my $global_variable = $_[0];
	my $level = $_[1];
	&print_level_to_tab($level);
	print "while (";
	&move_to_next_token;
	if ($token =~ m/^true$/) {
		print "1";
	} elsif ($token =~ m/^test$/) {
		&parse_test($global_variable, $level);
	} elsif ($token =~ m/^\[$/) {
		&parse_condition($global_variable);
	}
	print ") {\n";
	&move_to_next_token;
	$level = $level + 1;
	&parse_while_compound($global_variable, $level);
}

sub parse_func_call {
	my $global_variable = $_[0];
	my $level = $_[1];
	&print_level_to_tab($level);
	print "\&";
	&parse_variable($global_variable);
	&move_to_next_token;
	print "(";
	while ($token !~ m/\n$/ && $token !~ m/(&&|\|\|)/) {
		&parse_variable($global_variable);
		print ", ";
		&move_to_next_token;
	}

	if ($token =~ m/\n$/) {
		$token =~ s/\n//;
		&parse_variable;
		print ");\n";
	}

	if ($token =~ m/(&&|\|\|)/) {
		print ") ";
		&parse_function_logic_operator;
	}
}

sub parse_local {
	my $global_variable = $_[0];
	my $level = $_[1];
	&print_level_to_tab($level);
	print "my (";
	&move_to_next_token;
	while ($token !~ m/\n$/) {
		print "\$$token";
		print ", ";
		&move_to_next_token;
	}

	$token =~ s/\n//;
	print "\$$token";
	print ");\n";
}

sub parse_read {
	my $global_variable = $_[0];
	my $level = $_[1];
	&move_to_next_token;
	$token =~ s/\n//;
	&print_level_to_tab($level);
	print "\$$token = <STDIN>;\n";
	&print_level_to_tab($level);
	print "chomp \$$token;\n";
}

sub parse_comment {
	my $global_variable = $_[0];
	my $level = $_[1];
	&print_level_to_tab($level);
	while ($token !~ m/\n$/) {
		print "$token";
		print " ";
		&move_to_next_token;
	}
	print "$token";
}

sub parse_expr_expr {
	my $global_variable = $_[0];
	if ($token =~ /^\`expr/) {
		&move_to_next_token;
		while ($token !~ /\`\n?/) {
			&parse_expr_cases($global_variable);
			&move_to_next_token;
		}

		$token =~ s/\`//;
		$token =~ s/\n//;
		&parse_expr_cases($global_variable);
	} elsif ($token =~ /^\$\(expr/) {
		&move_to_next_token;
		while ($token !~ /\)\n/) {
			&parse_expr_cases($global_variable);
			&move_to_next_token;
		}
	}
}

# ---------------------------- Parse-if -------------------------- #
# if expression, there are generally two cases for if expresions:
# 1. normal if structure for example: if..then..fi which is simple
# 2. complex if structure for example: if..then..elif..then..fi
sub parse_if {
	my $global_variable = $_[0];
	my $level = $_[1];
	my $elsif = $_[2];
	&print_level_to_tab($level);
	if (defined $elsif) {
		print "} elsif (";
	} else {
		print "if (";
	}
	&move_to_next_token;
	if ($token =~ m/^test$/) {
		&parse_test($global_variable, $level);
	} elsif ($token =~ m/^\[$/) {
		&parse_condition($global_variable);
	} elsif ($token =~ m/fgrep/) {
		print "! system \"fgrep ";
		&move_to_next_token;
		&parse_if_fgrep_flags;
		&parse_if_fgrep_parameters($global_variable);
		print "\"";
	}
	print ") {\n";
	&move_to_next_token;
	$level = $level + 1;
	&parse_if_compound($global_variable, $level); 
	if (!defined $elsif) {
		$level = $level - 1;
		&print_level_to_tab($level);
		print "}\n";
	}
}

# ---------------------------- Parse-for -------------------------- #
# for expression is very similar with while expression, at this stage
# I only translate for expression in Shell to foreach expression in perl
# There are two cases need to consider for for expression:
# 1. normal for expression, for example: for $word in ( some words )
# 2. check the directory using for loop: for $file in (*.c)
sub parse_for {
	my $global_variable = $_[0];
	my $level = $_[1];
	&print_level_to_tab($level);
	print "foreach";
	print " ";
	&move_to_next_token;
	print "\$$token";
	&move_to_next_token;
	&move_to_next_token;
	print " ";
	print "(";
	if ($token =~ m/\n$/) {
		$token =~ s/\n//;
		print "glob(\"$token\")";
		print ") {\n";
		&move_to_next_token;
	} else {
		while ($token !~ /do/) {
			$token =~ s/\n//;
			if ($token !~ m/^( |\n)*$/) {
				&parse_for_condition($global_variable);
				if ($tokens[$token_pos+1] !~ /do|^\n$/) {
					print ", ";
				}
			}
			&move_to_next_token;
		}
		print ") {\n";
	}
	&move_to_next_token;
	$level = $level + 1;
	&parse_for_compound($global_variable, $level);
}

sub parse_case_pattern {
	my $level = $_[0];
	&print_level_to_tab($level);
	$token =~ s/\n//;
	$token =~ s/\)//;
	$token =~ s/\"//g;
	&parse_variable;
	print "\/\) {\n";
}

# ---------------------------- Parse-case -------------------------- #
# For case...esac there are three parts for it:
# 1. declaration statement: case variable in
# 2. patterns, there will be many patterns under the whole case
# 3. compound expressions, under each pattern there will be some commands
sub parse_case {
	my $global_variable = $_[0];
	my $level = $_[1];
	&print_level_to_tab($level);
	&move_to_next_token;
	my $var = $token;
	&move_to_next_token;
	&move_to_next_token;
	my $command_level = $level + 1;
	print "if ($var \=\~ \/";
	while ($token !~ /esac/) {
		if ($token !~ /^\*\)$/) {
			&parse_case_pattern($level);
		}
		&move_to_next_token;
		while ($token !~ /\;\;/) {
			&parse_exprs($global_variable, $command_level);
			&move_to_next_token;
		}
		&move_to_next_token;
		&print_level_to_tab($level);
		if ($token !~ /(^\*\)$|esac)/) {
			print "} elsif ($var \=\~ \/";
		} elsif ($token !~ /esac/) {
			print "} else {\n";
		}
	}
	&print_level_to_tab($level);
	print "}\n";
}

# ------------------------ helper functions ------------------------ #
# below are helper functions to help do the parsing work for above
# parse expressions.
sub move_to_next_token {
	if ($token_pos < @tokens - 1) {
		$token_pos += 1;
		$token = $tokens[$token_pos];
	}

	while ($token =~ /^$/ && $token !~ /\n$/) {
		if ($token_pos < @tokens - 1) {
			print " ";
			$token_pos += 1;
			$token = $tokens[$token_pos];
		}
	}
}

sub print_level_to_tab {
	my $level = $_[0];
	$i = 0;
	while ($i < $level) {
		print "	";
		$i++;
	}
}

sub parse_expr_cases {
	my $global_variable = $_[0];
	if ($token =~ /[\+\-\*\/\%]/) {
		$token =~ s/\'//g;
		print " $token ";
	} elsif ($token =~ /^[0-9]+$/) {
		print "$token";
	} else {
		&parse_variable($global_variable);
	}
}

# For shell variables there are 3 cases:
# 1. normal variables which just start from dollar and composed of letters and numbers
# 2. normal variables but with quotes, double quotes or single quotes around the variable
# 3. special variables like $1, $2, $3, $#...which from progarm args or function args
sub parse_variable {
	my $global_variable = $_[0];
	if ($token =~ /^\$[a-zA-Z_]+[0-9]*[a-zA-Z_]*$/) {
		$token =~ s/^\$//;
		print("\$$token");
	} elsif ($token =~ /^\$[0-9]+$/) {
		$token =~ s/^\$//;
		$token -= 1;
		if ($global_variable == 1) {
			print("\$ARGV[$token]");
		}
		if ($global_variable == 0) {
			print("\$\_[$token]");
		}
	} elsif ($token =~ m/^\"\$[a-zA-Z_]+[0-9]*[a-zA-Z_]*\"$/) {
		$token =~ s/\"\$//g;
		print "\\\"\$";
		print "$token";
		print "\\\"";
	} elsif ($token =~ m/^\"[^\$]/) {
		$token =~ s/\"//g;
		print "\\\"";
		print "$token";
		print "\\\"";
	} elsif ($token =~ m/^\'\$[a-zA-Z_]+[0-9]*[a-zA-Z_]*\'$/) {
		$token =~ s/\'\$//g;
		print "\\\'\$";
		print "$token";
		print "\\\'";
	} elsif ($token =~ m/^\'[^\$]/) {
		$token =~ s/\'//g;
		print "\\\'";
		print "$token";
		print "\\\'";
	} elsif ($token =~ m/^\$\#$/) {
		if ($global_variable == 1) {
			print "\$\#ARGV+1";
		} else {
			print "\$\#\_+1";
		}
	} elsif ($token =~ m/^\$\*$/ || $token =~ m/^\"\$\*\"$/) {
		if ($global_variable == 1) {
			print "\@ARGV";
		} else {
			print "\@\_";
		}
	} elsif ($token =~ m/^\$\@$/ || $token =~ m/^\"\$\@\"$/) {
		if ($global_variable == 1) {
			print "\@ARGV";
		} else {
			print "\@\_";
		}
	}
	else {
		$token =~ s/\n//;
		print "$token";
	}
}

sub parse_write_file {
	my $end_pos = $_[0];
	my $level = $_[1];
	my $global_variable = $_[2];
	my $new_line = $_[3];
	&print_level_to_tab($level);
	$file = $tokens[$end_pos] =~ s/\n//r;
	$file =~ s/\"//g;
	if ($file =~ /^\>[^\>]/) {
		$file =~ s/\>//;
		print "open F, \'>\', \"$file\" or die;\n";
	} elsif ($file =~ /^\>\>/) {
		$file =~ s/\>//g;
		print "open F, \'>>\', \"$file\" or die;\n";
	}

	&print_level_to_tab($level);
	print "print F \"";
	while ($token !~ /^\>/ && $tokens[$token_pos+1] !~ /^\>/) {
		&parse_echo_cases($global_variable);
		print " ";
		&move_to_next_token;
	}

	&parse_echo_cases($global_variable);
	if ($new_line == 1) {
		print "\\n\";\n";
	} else {
		print "\";\n";
	}

	&print_level_to_tab($level);
	print "close F;\n";

	&move_to_next_token;
}

sub parse_echo_cases {
	my $global_variable = $_[0];
	if ($token =~ /^[^\$\"\']/) {
		$token =~ s/\"/\\\"/g;
		$token =~ s/\'/\\\'/g; 
		print "$token";
	} elsif ($token =~ /^\$/) {
		&parse_variable($global_variable);
	} elsif ($token =~ /^\"/) {
		if ($token =~ /^\"\$/) {
			$token =~ s/\"//g;;
			&parse_variable($global_variable);
		} else {
			$token =~ s/\"/\\\"/g;
			$token =~ s/\'/\\\'/g;
			print "$token";
		}
	} elsif ($token =~ /^\'/) {
		if ($token =~ /^\'\$/) {
			$token =~ s/^\'//g;
			&parse_variable($global_variable);
		} else {
			$token =~ s/\"/\\\"/g;
			$token =~ s/\'/\\\'/g;
			print "$token";
		}
	}
}

sub parse_test_operator {
	if ($token =~ m/=|\!=/) {
		if ($token =~ m/^=$/) {
			print "eq";
		} elsif ($token =~ m/^\!=$/) {
			print "ne"
		}
	} elsif ($token =~ m/-lt|-le|-eq|-gt|-ge|-ne/) {
		if ($token =~ m/-lt/) {
			print "<";
		} elsif ($token =~ m/-le/) {
			print "<=";
		} elsif ($token =~ m/-eq/) {
			print "==";
		} elsif ($token =~ m/-gt/) {
			print ">";
		} elsif ($token =~ m/-ge/) {
			print ">=";
		} elsif ($token =~ m/-ne/) {
			print "!=";
		}
	} else {
		print "$token";
	}
}

sub parse_test_parameter {
	$global_variable = $_[0];
	if ($token =~ m/^\$\(\(/) {
		$token =~ s/\(//g; 
		print "$token";
		print " ";
		&move_to_next_token;
		print "$token";
		print " ";
		&move_to_next_token;
		$token =~ s/\)//g;
		$token =~ s/\n//;
		if ($token =~ m/^[0-9]+$/) {
			print "$token";
		} else {
			print "\$$token";
		}
	} elsif ($token !~ m/\$/ && $token !~ m/^[0-9]+$/) {
		$token =~ s/\n//;
		if ($token =~ m/^-/) {
			print "$token";
		} else {
			print "\'";
			$token =~ s/\n//;
			$token =~ s/\"//g;
			print "$token";
			print "\'";
		}
	} else {
		$token =~ s/\n//;
		&parse_variable($global_variable);
	}
}

# This is the translation for logic operators, && --> and, || --> or
# This is different from function logic operators, because function
# logic operators should be swapped, for function success return 1 but
# fail will return 0, for function the logic operators will be swapped
sub parse_logic_operators {
	if ($token =~ m/&&/) {
		print "and";
	} else {
		print "or";
	}
}

sub parse_function_logic_operator {
	if ($token =~ m/&&/) {
		print "or";
	} else {
		print "and";
	}
}

# boolean operators translation, for below three boolean operators which
# are likely to be used by composite test expresions. !->!, -o->||, -a->&&
sub parse_bool_operators {
	if ($token =~ /\!/) {
		print " ! ";
	} elsif ($token =~ /-o/) {
		print " || ";
	} elsif ($token =~ /-a/) {
		print " && ";
	}
}

sub parse_test_nest {
	my $global_variable = $_[0];
	&parse_test_parameter($global_variable);
	print " ";
	&move_to_next_token;
	if ($tokens[$token_pos-1] =~ /^-[a-zA-Z]/) {
		&parse_test_parameter($global_variable);
		&move_to_next_token;
	} else {
		if ($token !~ m/\n$/) {
			&parse_test_operator;
			print " ";
			&move_to_next_token;
		}
		&parse_test_parameter($global_variable);
		&move_to_next_token;
		if ($token =~ /^\n$/) {
			&move_to_next_token;
		}
	}

	if ($token =~ m/&&|\|\|/) {
		print " ";
		&parse_logic_operators;
		print " ";
	} elsif ($token =~ /(!|-o|-a)/) {
		&parse_bool_operators;
		&move_to_next_token;
		&parse_test_nest($global_variable);
	}
}

sub parse_condition_nest {
	my $global_variable = $_[0];
	&parse_test_parameter($global_variable);
	print " ";
	&move_to_next_token;
	if ($tokens[$token_pos+1] =~ /\]/) {
		&parse_test_parameter;
		&move_to_next_token;
		&move_to_next_token;
	} else {
		if ($token !~ m/\n$/) {
			&parse_test_operator;
			print " ";
			&move_to_next_token;
		}
		&parse_test_parameter($global_variable);
		&move_to_next_token;
		&move_to_next_token;
		if ($token =~ /^\n$/) {
			&move_to_next_token;
		}
	}
	if ($token =~ m/&&|\|\|/) {
		print " ";
		&parse_logic_operators;
		print " ";
		&move_to_next_token;
		&move_to_next_token;
		&parse_condition_nest($global_variable);
	} 
}

sub parse_if_fgrep_flags {
	while ($token =~ /^\-[a-zA-Z]/) {
		print "$token";
		print " ";
		&move_to_next_token;
	}
}

sub parse_if_fgrep_parameters {
	$global_variable = $_[0];
	while ($token !~ /\n$/) {
		&parse_variable($global_variable);
		print " ";
		&move_to_next_token;
	}
	$token =~ s/\n//;
	&parse_variable($global_variable);
	&move_to_next_token;
}

sub parse_for_condition {
	$global_variable = $_[0];
	if ($token =~ m/^[0-9]+$/) {
		print "$token";
	} else {
		print "\'";
		&parse_variable($global_variable);
		print "\'";
	}
}

# ----------------- compound expression (if, for, while) ------------- #
# Treat all the commands under if, for, while as compound expressions,
# when parse if, for, while expression will pasre all the expression inside
# as a whole block. Below three functions are for if, for and while.
sub parse_if_compound {
	my $global_variable = $_[0];
	my $level = $_[1];
	my $elsif = 0;
	while ($token !~ /fi/) {
		if ($token =~ m/^( |\n)*$/) {
			&move_to_next_token;
			next;
		}

		if ($token =~ /elif/) {
			$level = $level - 1;
			&print_level_to_tab($level);
			$elsif = 1;
			&parse_if($global_variable, $level, $elsif);
			$elsif = 0;
		} elsif ($token =~ /else/) {
			$level = $level - 1;
			&print_level_to_tab($level);
			print "} else {\n";
			&move_to_next_token;
			$level = $level + 1;
		} 
		else {
			if ($token !~ m/then/) {
				&parse_exprs($global_variable, $level);
				&move_to_next_token;
			}
		}
		
	}
}

sub parse_for_compound {
	my $global_variable = $_[0];
	my $level = $_[1];
	while ($token !~ m/^done\n?$/) {
		if ($token =~ m/^( |\n)*$/) {
			&move_to_next_token;
			next;
		}
		&parse_exprs($global_variable, $level);
		&move_to_next_token;
	}

	$level = $level - 1;
	&print_level_to_tab($level);
	print "}\n";
}

sub parse_while_compound {
	my $global_variable = $_[0];
	my $level = $_[1];
	while ($token !~ m/^done\n?$/) {
		if ($token =~ m/^( |\n|do)*$/) {
			&move_to_next_token;
			next;
		}
		&parse_exprs($global_variable, $level);
		&move_to_next_token;
	}

	$level = $level - 1;
	&print_level_to_tab($level);
	print "}\n";
}

parse_shell;
