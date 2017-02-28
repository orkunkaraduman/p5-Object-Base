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


################################################################################
# Object::Base
################################################################################
	package Foo;
	use Object::Base;
	attributes ':shared', 'attr1', 'attr2';
	#
	package Bar;
	use Object::Base 'Foo';
	my $attr3_def = 6;
	my $attr3_val;
	attributes ':shared' => undef, 'attr2' => undef, ':lazy',
		'attr3' => {
			'default' => sub {
				my ($self, $key) = @_;
				print "> default key=$key\n";
				$attr3_val = $attr3_def-1;
				return $attr3_def;
			},
			'getter' => sub {
				my ($self, $key) = @_;
				print "> getter key=$key\n";
				return $attr3_val+1;
			},
			'setter' => sub {
				my ($self, $key, $value) = @_;
				print "> setter key=$key value=$value\n";
				$attr3_val = $value-1;
			},
		}
	;
	#
	package main;
	use threads;
	use threads::shared;
	#
	# object of Foo
	my $foo = Foo->new();
	#
	# special attribute ':shared'
	print "\$foo is ", is_shared($foo)? "shared": "not shared", "\n";
	#
	# usage of attribute
	$foo->attr1(1);
	print $foo->attr1, "\n"; # prints '1'
	#
	# attributes are lvalued
	$foo->attr1++;
	print $foo->attr1, "\n"; # prints '2'
	#
	# assigning ref values to shared class attributes
	eval { $foo->attr2 = { key1 => 'val1' } }; print "Eval: $@"; # prints error 'Eval: Invalid value for shared scalar at ...'
	$foo->attr2({ key2 => 'val2' }); # uses shared_clone assigning ref value
	print $foo->attr2->{key2}, "\n"; # prints 'val2'
	#
	# object of derived class Bar
	my $bar = Bar->new();
	#
	# features are overridable
	print "\$bar is ", is_shared($bar)? "shared": "not shared", "\n"; # prints '$bar is not shared'
	#
	# attributes can be added derived classes
	# attributes can have modifiers: default
	print "attr3 default value is ", $bar->attr3, "\n"; # prints 'attr3 default value is 6'
	#
	# attributes can have modifiers: setter
	$bar->attr3 = 3;
	print "attr3 set", "\n";
	#
	# attributes can have modifiers: getter
	print "attr3 value ", $bar->attr3, " and stored as $attr3_val", "\n"; # prints 'attr3 value 3 and stored as 2'
	#
	# attributes are inheritable
	$bar->attr1(3);
	#
	# attributes are overridable
	eval { $bar->attr2 = 4 }; print "Eval: $@"; # prints error 'Eval: Attribute attr2 is not defined in Bar at ...'
	#
	# attributes in thread
	my $thr1 = threads->create(sub { $foo->attr1 = 5; $bar->attr1 = 5; });
	my $thr2 = threads->create(sub { sleep 1; print "\$foo is shared and attr1: ", $foo->attr1, ", \$bar is not shared and attr1: ", $bar->attr1, "\n"; });
	# prints '$foo is shared and attr1: 5, $bar is not shared and attr1: 3'
	$thr1->join();
	$thr2->join();
################################################################################


################################################################################
# Object::Exception
################################################################################
	package SampleException;
	use Object::Base qw(Object::Exception);
	#
	package main;
	use Object::Exception;
	#
	# Enable DEBUG for traceback
	our $DEBUG = 1;
	#
	# throws Object::Exception type and its msg: Exception1
	eval
	{
		throw("Exception1");
	};
	if ($@)
	{
		warn $@ if ref($@) eq "Object::Exception";
	}
	#
	# throws SampleException type and its msg: This is sample exception
	sub sub_exception
	{
		SampleException->throw("This is sample exception");
	}
	eval
	{
		sub_exception();
	};
	if ($@) {
		# $@ and $@->message returns same result
		warn $@->message if ref($@) eq "SampleException";
	}
	#
	# throws Object::Exception type and its message: SampleException. Because msg is not defined!
	eval
	{
		SampleException->throw();
	};
	if ($@)
	{
		if (ref($@) eq "SampleException")
		{
			warn $@;
		} else
		{
			# warns 'This is type of Object::Exception and its message: SampleException'
			warn "This is type of ".ref($@)." and its message: $@";
		}
	}
################################################################################


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
