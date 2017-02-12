package Object::Base;
=head1 NAME

Object::Base - Multi-threaded base class to establish a class deriving relationship with parent classes

=head1 VERSION

version 1.08

=head1 ABSTRACT

Multi-threaded base class to establish a class deriving relationship with parent classes

	package Foo;
	use Object::Base;
	my $attr3_def = 6;
	my $attr3_val;
	attributes ':shared', 'attr1', 'attr2', ':lazy',
		'attr3' => {
			'default' => sub {
				my ($self, $key) = @_;
				$attr3_val = $attr3_def;
				return $attr3_def;
			},
			'getter' => sub {
				my ($self, $key) = @_;
				return $attr3_val+1;
			},
			'setter' => sub {
				my ($self, $key, $value) = @_;
				$attr3_val = $value-1;
			},
		};
	
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
	
	# attributes can have modifiers: default, getter, setter
	print "attr3 value ", $foo->attr3, " and stored as $attr3_val", "\n"; # prints 'attr3 value 7 and stored as 6'
	
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
	
	# attributes in thread
	my $thr1 = threads->create(sub { $foo->attr1 = 5; $bar->attr1 = 5; });
	my $thr2 = threads->create(sub { sleep 1; print "\$foo is shared and attr1: ", $foo->attr1, ", \$bar is not shared and attr1: ", $bar->attr1, "\n"; });
	# prints '$foo is shared and attr1: 5, $bar is not shared and attr1: 3'
	$thr1->join();
	$thr2->join();

=head1 DESCRIPTION

Object::Base provides blessed and thread-shared(with :shared feature) object with in B<new> method. B<new> method
can be used as a constructor and overridable in derived classes. B<new()> should be called in derived class
constructors to create and bless self-object.

Derived classes own package automatically uses threads, threads::shared, strict, warnings with using Object::Base. If
Perl is not built to support threads; it uses forks, forks::shared instead of threads, threads::shared. Object::Base
should be loaded as first module.

Import parameters of Object::Base, define parent classes of derived class.
If none of parent classes derived from Object::Base or any parent isn't defined, Object::Base is automatically added
in parent classes.

=head2 Attributes

Attributes define read-write accessors binded value of same named key in objects own hash if attribute names is
valid subroutine identifiers. Otherwise, attribute defines B<feature> to get new features into class.

Attributes;

=over

=item *

Lvaluable

=item *

Inheritable

=item *

Overridable

=item *

Redefinable

=item *

Thread-Safe

=back

=head3 Modifiers

Attributes can have their own modifiers in hash reference at definition.

=head4 default

getter method of default value of attribute, otherwise value is default value

	attributes
		'attr1' => {
			'default' => sub {
				my ($self, $key) = @_;
				return "default value of $key";
			},
		},
		'attr2' => {
			'default' => "default value of attr2",
		};

=head4 getter

getter method of attribute

	my $attr1_val;
	attributes
		'attr1' => {
			'getter' => sub {
				my ($self, $key) = @_;
				return $attr1_val;
			},
		};

=head4 setter

setter method of attribute

	my $attr1_val;
	attributes
		'attr1' => {
			'setter' => sub {
				my ($self, $key, $value) = @_;
				$attr1_val = $value;
			},
		};

=head3 Features

=head4 :shared

Class will be craated as thread-shared.

=head4 :lazy

Attributes will be initialized with default values at first fetching or storing instead of object construction with new().

=cut
BEGIN
{
	if ($Config::Config{'useithreads'})
	{
		require threads;
		threads->import();
		require threads::shared;
		threads::shared->import();
	} else
	{
		require forks;
		forks->import();
		require forks::shared;
		forks::shared->import();
	}
}
use strict;
no strict qw(refs);
use warnings;


BEGIN
{
	require 5.008;
	$Object::Base::VERSION = '1.08';
	$Object::Base::ISA = ();
}


my $package = __PACKAGE__;
my $context = $package;
$context =~ s/\Q::\E//g;


sub import
{
	die "$package can not be imported at run-time" if ${^GLOBAL_PHASE} eq "RUN";
	my $importer = shift;
	my $caller = caller;
	return unless $importer eq $package;
	eval join "\n",
		"package $caller;",
		<< "EOF",
BEGIN
{
	if (\$Config::Config{'useithreads'})
	{
		require threads;
		threads->import();
		require threads::shared;
		threads::shared->import();
	} else
	{
		require forks;
		forks->import();
		require forks::shared;
		forks::shared->import();
	}
}
use SUPER;
EOF
		"use strict;",
		"use warnings;",
		"",
		(exists(&{"${caller}::attributes"})? "": "sub attributes { ${package}::attributes(\@_) }"),
		"",
		"\%${caller}::${context} = () unless defined(\\\%${caller}::${context});",
		"",
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
		"package $caller;",
		"",
		map {
			<< "EOF";
sub $_ :lvalue
{
	my \$self = shift;
	die 'Attribute $_ is not defined in $caller' unless
		defined(\$self) and
		UNIVERSAL::isa(ref(\$self), '$package') and
		\$${caller}::${context}{"$_"};
	my \@args = \@_;
	if (\@args >= 1)
	{
		unless (is_shared(%{\$self}) and ref(\$args[0]) and not is_shared(\$args[0]))
		{
			\$self->{"$_"} = \$args[0];
		} else
		{
			\$self->{"$_"} = shared_clone(\$args[0]);
		}
	}
	\$self->{"$_"};
}
EOF
		} grep { /^[^\W\d]\w*\z/s and not exists(&{"${caller}::$_"}) } keys %{"${caller}::${context}"};
	die "Failed to generate attributes in $caller: $@" if $@;
	return 1;
}

sub new
{
	my $class = shift;
	die "Invalid $package class" unless
		defined($class) and
		not ref($class) and
		UNIVERSAL::isa($class, $package);
	die "$package context is not defined" unless defined(\%{"${class}::${context}"});
	my $self = {};
	tie %$self, "${package}::TieHash", $class, \$self unless ${"${class}::${context}"}{":shared"};
	$self = shared_clone($self) if ${"${class}::${context}"}{":shared"};
	bless $self, $class;
}

sub DESTROY
{
}


package Object::Base::TieHash;
BEGIN
{
	if ($Config::Config{'useithreads'})
	{
		require threads;
		threads->import();
		require threads::shared;
		threads::shared->import();
	} else
	{
		require forks;
		forks->import();
		require forks::shared;
		forks::shared->import();
	}
}
use strict;
no strict qw(refs);
use warnings;


BEGIN
{
	require 5.008;
	$Object::Base::TieHash::VERSION = '1.08';
}


sub TIEHASH
{
	my $class = shift;
	my $self = [{}, @_, {}];
	bless $self, $class;
	for (grep /^[^\W\d]\w*\z/s, keys(%{"$self->[1]::${context}"}))
	{
		$self->[0]->{$_} = undef;
		$self->def($_) unless ${"$self->[1]::${context}"}{":lazy"};
	}
	$self;
}

sub STORE
{
	my $self = shift;
	my ($key, $value) = @_;
	return unless $key =~ /^[^\W\d]\w*\z/s;
	$self->def($key);
	my $attr = ${"$self->[1]::${context}"}{$key};
	if (ref($attr) eq 'HASH' and exists($attr->{"setter"}))
	{
		my $setter = $attr->{"setter"};
		if (ref($setter) eq 'CODE')
		{
			$setter->(${$self->[2]}, $key, $value);
		}
	}
	$self->[0]->{$key} = $value;
}

sub FETCH
{
	my $self = shift;
	my ($key) = @_;
	return unless $key =~ /^[^\W\d]\w*\z/s;
	$self->def($key);
	my $attr = ${"$self->[1]::${context}"}{$key};
	if (ref($attr) eq 'HASH' and exists($attr->{"getter"}))
	{
		my $getter = $attr->{"getter"};
		if (ref($getter) eq 'CODE')
		{
			$self->[0]->{$key} = $getter->(${$self->[2]}, $key);
		}
	}
	$self->[0]->{$key};
}

sub EXISTS
{
	exists $_[0][0]->{$_[1]};
}

sub DELETE
{
	delete $_[0][$#{$_[0]}]->{$_[1]};
	delete $_[0][0]->{$_[1]};
}

sub CLEAR
{
	%{$_[0][$#{$_[0]}]} = ();
	%{$_[0][0]} = ();
}

sub FIRSTKEY
{
	my $a = scalar keys %{$_[0][0]};
	each %{$_[0][0]};
}

sub NEXTKEY
{
	each %{$_[0][0]};
}

sub SCALAR
{
	scalar %{$_[0][0]};
}

sub def
{
	my $self = shift;
	my ($key) = @_;
	unless (exists($self->[$#{$self}]->{$key}))
	{
		my $val = undef;
		my $attr = ${"$self->[1]::${context}"}{$key};
		if (ref($attr) eq 'HASH' and exists($attr->{"default"}))
		{
			my $default = $attr->{"default"};
			if (ref($default) eq 'CODE')
			{
				$val = $default->(${$self->[2]}, $key);
			} else
			{
				$val = $default;
			}
		}
		$self->[$#{$self}]->{$key} = $val;
		$self->[0]->{$key} = $val;
	}
	return $self->[$#{$self}]->{$key};
}


1;
__END__
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
