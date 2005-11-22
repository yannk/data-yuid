# $Id$

use strict;
use Data::YUID::Generator;
use Test::More tests => 3;

my $gen = Data::YUID::Generator->new;
isa_ok($gen, 'Data::YUID::Generator');
my $id1 = $gen->get_id;
ok($id1);
my $id2 = $gen->get_id;
isnt($id1, $id2);
