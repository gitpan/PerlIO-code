#!perl
use strict;
use warnings;
use Test::More 'no_plan';

use PerlIO::code;

my $o;
my @data = ("foo\n", "bar\n", "baz");
sub input{
	return shift @data;
}

sub output{
	($o) = @_;
}

my $fh;
ok open($fh, "<", \&input), "open for reading";

is scalar(<$fh>), "foo\n", "readline:0";
is scalar(<$fh>), "bar\n", "readline:1";
is scalar(<$fh>), "baz",   "readline:2";
ok !defined(<$fh>),        "readline:undef";
ok !defined(<$fh>),        "readline:undef (again)";
ok eof($fh), "eof";

ok close($fh), "close";

ok open($fh, ">", \&output), "open for writing";

print $fh "foo\n";

is $o, "foo\n", "print";

print $fh "bar";

is $o, "bar", "print";

ok close($fh), "close";

is $o, "bar", "print (after closed)";

# errors

ok open(my $c, '+<', \&notfound), 'open';
eval{
	my $s = <$c>;
};
ok $@, 'undefined subroutine';

eval{
	print $c "foo";
};
ok $@, 'undefined subroutine';

