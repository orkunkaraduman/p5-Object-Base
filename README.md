# NAME

Object::Base - Multi-threaded base class to establish a class deriving relationship with base classes at compile time

# VERSION

version 1.00

# ABSTRACT

Multi-threaded base class to establish a class deriving relationship with base classes at compile time

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
        
        # attributes are also lvaluable
        $foo->attr1++;
        print $foo->attr1, "\n"; # prints '2'
        
        # class attributes, eg: ':shared'
        print "\$foo is ", is_shared($foo)? "shared": "not shared", "\n";
        
        # object of derived class Bar
        my $bar = Bar->new();
        
        # attributes can be added derived classes
        $bar->attr3(3);
        
        # attributes are inheritable
        $bar->attr1(3);
        
        # attributes are overridable #1
        eval { $bar->attr2 = 4 }; print $@; # prints error 'Attribute attr2 is not defined in Bar at ...'
        
        # attributes are overridable #2
        print "\$bar is ", is_shared($bar)? "shared": "not shared", "\n"; # prints '$bar is not shared'
        
        # assigning ref values to shared class attributes
        eval { $foo->attr2 = { key1 => 'val1' } }; print $@; # prints error 'Invalid value for shared scalar at ...'
        $foo->attr2({ key2 => 'val2' }); # uses shared_clone assigning ref value

# DESCRIPTION

Base class for Perl objects

...

# INSTALLATION

To install this module type the following

        perl Makefile.PL
        make
        make test
        make install

from CPAN

        cpan -i Object::Base

# DEPENDENCIES

This module requires these other modules and libraries:

> There is no dependency for this module.

# REPOSITORY

**GitHub** [https://github.com/orkunkaraduman/p5-Object-Base](https://github.com/orkunkaraduman/p5-Object-Base)

**CPAN** [https://metacpan.org/release/Object-Base](https://metacpan.org/release/Object-Base)

# AUTHOR

Orkun Karaduman &lt;orkunkaraduman@gmail.com&gt;

# COPYRIGHT AND LICENSE

Copyright (C) 2017  Orkun Karaduman &lt;orkunkaraduman@gmail.com&gt;

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see &lt;http://www.gnu.org/licenses/&gt;.
