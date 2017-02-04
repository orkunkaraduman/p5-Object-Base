package Object::Base;
=head1 NAME

Object::Base - Multi-threaded base class to establish a class deriving relationship with base classes

=head1 VERSION

version 1.03

=head1 ABSTRACT

Multi-threaded base class to establish a class deriving relationship with base classes

	package Foo;
	use Object::Base;
	
	package Bar;
	use Object::Base qw('Foo', 'Baz');
	attributes 'attr1', 'attr2', ':shared';

=head1 DESCRIPTION

Object::Base provides blessed and thread-shared(with :shared attribute) object with in B<new> method. B<new> method
can be used as a constructor and overridable in derived classes. B<new()> should be called in derived class
constructors to create and bless self-object. Derived classes own module automatically uses strict, warnings, threads,
threads::shared with using Object::Base. Import parameters of Object::Base, define parent classes of derived class.
If none of parent classes derived from Object::Base or any parent isn't defined, Object::Base is automatically added
in parent classes.

Attributes define read-write accessors binded value of same named key in objects own hash if attribute names is
valid subroutine identifiers. Otherwise, attribute is special to get new features into class.

Attributes;

=over

=item *

Lvaluable

=item *

Inheritable

=item *

Overridable

=back

Examples;

	package Foo;
	use Object::Base;
	attributes ':shared', 'attr1', 'attr2';
	
	package Bar;
	use Object::Base 'Foo';
	attributes 'attr3', ':shared' => undef, 'attr2' => undef;
	
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

=cut
use strict;
no strict qw(refs);
use warnings;
use threads;
use threads::shared;


BEGIN
{
	require 5.008;
	$Object::Base::VERSION = '1.03';
	$Object::Base::ISA = ();
}


my $package = __PACKAGE__;
my $context = $package;
$context =~ s/\Q::\E//g;


sub import
{
	my $importer = shift;
	my $caller = caller;
	return unless $importer eq $package;
	eval join "\n",
		"package $caller;",
		"use strict;",
		"use warnings;",
		"use threads;",
		"use threads::shared;",
		"\$${caller}::attributes = undef;",
		"\*${caller}::attributes = \\\&${package}::attributes;",
		"\%${caller}::${context} = () unless defined(\\\%${caller}::${context});",
		(
			map {
				my $p = (defined and not ref)? $_: "";
				$p and /^[^\W\d]\w*(\:\:[^\W\d]\w*)*\z/s or die "Invalid base-class name $p";
				<< "EOF";
eval { require $_ };
push \@${caller}::ISA, '$_';
if ($_->isa('$package'))
{
	\$${caller}::${context}{\$_} = \$$_::${context}{\$_} for (keys \%$_::${context});
}
EOF
			} @_
		),
		"push \@${caller}::ISA, '$package' unless UNIVERSAL::isa('${caller}', '$package');";
	die "Failed to import $package in $caller: $@" if $@;
	return 1;
}

sub attributes
{
	my $caller = caller;
	die "$caller is not $package class" unless UNIVERSAL::isa($caller, $package);
	%{"${caller}::${context}"} = () unless defined(\%{"${caller}::${context}"});
	my $l;
	for (@_)
	{
		if (not defined($_) or ref($_))
		{
			next if not defined($l) or ref($l);
			${"${caller}::${context}"}{$l} = $_;
			next;
		}
		${"${caller}::${context}"}{$_} = {};
	} continue
	{
		$l = $_;
	}
	eval join "\n",
		"\n",
		"package $caller;",
		"\n",
		map {
			<< "EOF";
sub $_ :lvalue
{
	my \$self = shift;
	die 'Attribute $_ is not defined in $caller' if not defined(\$self) or
		not UNIVERSAL::isa(ref(\$self), '$package') or
		not \$${caller}::${context}{"\Q$_\E"};
	my \@args = \@_;
	if (\@args >= 1)
	{
		my \$value;
		if (\@args == 1)
		{
			\$value = \\\$args[0];
		} elsif (\@args > 1)
		{
			\$value = \\\@args;
		}
		\$value = shared_clone(\$value) if \$${caller}::${context}{':shared'};
		\$self->{"\Q$_\E"} = \$value;
	}
	if (wantarray)
	{
		if (ref(\$self->{"\Q$_\E"}) eq 'SCALAR')
		{
			return (\${\$self->{"\Q$_\E"}});
		}
		return \@{\$self->{"\Q$_\E"}};
	} elsif (defined(wantarray))
	{
		if (ref(\$self->{"\Q$_\E"}) eq 'ARRAY')
		{
			return \@{\$self->{"\Q$_\E"}}[0];
		}
		return \${\$self->{"\Q$_\E"}};
	} else
	{
		return;
	}
}
EOF
		} grep { /^[^\W\d]\w*\z/s and not exists(&{"${caller}::$_"}) } keys %{"${caller}::${context}"};
	die "Failed to generate attributes in $caller: $@" if $@;
	return 1;
}

sub new
{
	my $class = shift;
	die "Invalid self-class" unless defined($class) and not ref($class) and UNIVERSAL::isa($class, $package);
	die "$package context is not defined" unless defined(\%{"${class}::${context}"});
	my $self = {};
	tie %$self, "${package}::TieHash", $class;
	$self = shared_clone($self) if ${"${class}::${context}"}{":shared"};
	bless $self, $class;
}


package Object::Base::TieHash;
use strict;
no strict qw(refs);
use warnings;
use threads;
use threads::shared;
use SUPER;


BEGIN
{
	require 5.008;
	$Object::Base::TieHash::VERSION = $Object::Base::VERSION;
	$Object::Base::TieHash::ISA = ('Tie::StdHash');
}


sub TIEHASH
{
	my $class = shift;
	my ($belongsto) = @_;
	my $self = $class->SUPER();
	$self = shared_clone($self) if ${"${belongsto}::${context}"}{":shared"};
	$self;
}

sub FETCH
{
	my $self = shift;
	my ($key) = @_;
	$self->{$key};
}

sub STORE
{
	my $self = shift;
	my ($key, $value) = @_;
	$self->{$key} = $value;
}


1;
__END__
=head1 INSTALLATION

To install this module type the following

	perl Makefile.PL
	make
	make test
	make install

from CPAN

	cpan -i Object::Base

=head1 DEPENDENCIES

This module requires these other modules and libraries:

=over

=item *

threads

=item *

threads::shared

=back

=head1 REPOSITORY

B<GitHub> L<https://github.com/orkunkaraduman/p5-Object-Base>

B<CPAN> L<https://metacpan.org/release/Object-Base>

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
