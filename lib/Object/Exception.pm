package Object::Exception;
=head1 NAME

Object::Exception - Multi-threaded base exception class

=head1 VERSION

version 1.08

=head1 ABSTRACT

Multi-threaded base exception class

	package SampleException;
	use Object::Base qw(Object::Exception);
	
	package main;
	use Object::Exception;
	
	# Enable DEBUG for traceback
	our $DEBUG = 1;
	
	# throws Object::Exception type and its msg: Exception1
	eval {
		throw("Exception1");
	};
	if ($@) {
		warn $@ if ref($@) eq "Object::Exception";
	}
	
	# throws SampleException type and its msg: This is sample exception
	sub sub_exception()
	{
		SampleException->throw("This is sample exception");
	}
	eval {
		sub_exception();
	};
	if ($@) {
		# $@ and $@->message returns same result
		warn $@->message if ref($@) eq "SampleException";
	}
	
	# throws Object::Exception type and its message: SampleException. Because msg is not defined!
	eval {
		SampleException->throw();
	};
	if ($@) {
		if (ref($@) eq "SampleException")
		{
			warn $@
		} else
		{
			# warns 'This is type of Object::Exception and its message: SampleException'
			warn "This is type of ".ref($@)." and its message: $@";
		}
	}

=cut
use Object::Base qw(Exporter);
use overload '""' => \&message;


BEGIN
{
	require 5.008;
	$Object::Exception::VERSION = '1.08';
	@Object::Exception::EXPORT = qw(throw);
}


attributes qw(:shared msg debug trace);


sub new
{
	my $class = shift;
	my ($msg) = @_;
	my $self = $class->SUPER();
	$self->msg = $msg;
	$self->debug = (defined($main::DEBUG) and $main::DEBUG)? 1: 0;
	return $self;
}

sub traceback
{
	my ($i) = @_;
	$i = 0 unless defined($i);
	my @result;
	while (scalar(my @caller = caller($i++)))
	{
		my @a;
		my @caller_next = caller($i);
		@a = split "::", $caller_next[3];
		my $sub = $a[$#a];
		push @result, {
			package => $caller[0],
			filename => $caller[1],
			line => $caller[2],
			subroutine => $sub,
		};
	}
	return @result;
}

sub dump_trace
{
	my @trace = @_;
	my $result = "";
	my $i = 0;
	for my $trace (reverse @trace)
	{
		$result .= sprintf("%-".((++$i)*2)."s", "");
		$result .= "in $trace->{package} ";
		$result .= "at ";
		$result .= "$trace->{subroutine} " if defined($trace->{subroutine});
		$result .= "$trace->{filename} ";
		$result .= "line $trace->{line}\n";
	} continue
	{
		$i++;
	}
	return $result;
}

sub throw
{
	my $class;
	if (@_ > 1)
	{
		$class = shift;
	} else
	{
		$class = __PACKAGE__;
	}
	my ($msg) = @_;
	return unless defined($class) and not ref($class) and UNIVERSAL::isa($class, __PACKAGE__);
	my $self = $class->new($msg);
	my @trace = traceback(1);
	$self->trace(\@trace);
	die $self;
}

sub message
{
	my $self = shift;
	my ($debug) = @_;
	$debug = $self->debug unless defined($debug);
	my $msg = $self->msg;
	my $result = "";
	$result .= "$msg\n" if defined($msg) and not ref($msg);
	return $result unless $debug;
	$result .= dump_trace(@{$self->trace});
	return $result;
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
