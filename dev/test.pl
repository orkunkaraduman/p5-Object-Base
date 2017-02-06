#! /usr/bin/perl
=head1 NAME

test.pl - for internal tests

=head1 VERSION

version not defined

=head1 ABSTRACT

for internal tests

=cut
use strict;
use warnings;
use v5.14;
use utf8;
use open qw(:utf8 :std);
use open IO => ':bytes';
use FindBin;
use Data::Dumper;

use lib "${FindBin::Bin}/../lib";


package Foo;
use Object::Base;
attributes ':shared', 'attr1', 'attr2';

package Bar;
use Object::Base 'Foo';
attributes 'attr3', ':shared' => undef, 'attr2' => { default => sub { return 7; }, getter => sub { my $a :shared = 101; return $a; }, setter => sub {  } }, ':lazy';

package main;
use threads;
use threads::shared;

# object of Foo
my $foo = Foo->new();

# usage of attribute
$foo->attr1(1);
print $foo->attr1, "\n"; # prints '1'

# attributes are lvalued
$foo->attr1++;
print $foo->attr1, "\n"; # prints '2'

# special attribute ':shared'
print "\$foo is ", is_shared($foo)? "shared": "not shared", "\n";

# object of derived class Bar
my $bar = Bar->new();

# attributes can be added derived classes
$bar->attr3(3);

say $bar->attr2++;

# attributes are inheritable
$bar->attr1(3);

# attributes are overridable #1
eval { $bar->attr2 = 4 }; print "Eval: $@"; # prints error 'Eval: Attribute attr2 is not defined in Bar at ...'

# attributes are overridable #2
print "\$bar is ", is_shared($bar)? "shared": "not shared", "\n"; # prints '$bar is not shared'

# assigning ref values to shared class attributes
eval { $foo->attr2 = { key1 => 'val1' } }; print "Eval: $@"; # prints error 'Eval: Invalid value for shared scalar at ...'
$foo->attr2({ key2 => 'val2' }); # uses shared_clone assigning ref value
print $foo->attr2->{key2}, "\n"; # prints 'val2'


{
	#my $a :shared = 10;
	#$foo->attr1 = \$a;
	#share(${$foo->attr1});
	print "\$foo attr1 is ", is_shared($a)? "shared": "not shared", "\n";
	#lock(${$foo->attr1});
}

#use Config;
say Dumper($Config::Config{'useithreads'});
say "OK";
exit 0;
__END__
=head1 AUTHOR

Orkun Karaduman <orkunkaraduman@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017  Orkun Karaduman <orkunkaraduman@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
