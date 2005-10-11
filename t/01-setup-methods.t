
use strict;

use Test::More 'no_plan';

use Test::FormValidator;

my $tfv = Test::FormValidator->new;

# test check() - we shouldn't be able to call it without a profile

eval {
    $tfv->check('foo' => 'bar');
};
ok($@, "prevented from calling check without a profile (input as hash)");
eval {
    $tfv->check({'foo' => 'bar'});
};
ok($@, "prevented from calling check without a profile (input as hashref)");


# test profile() - we should be able to switch profiles
$tfv->profile({ required => ['foo'] });
ok($tfv->check('foo' => 1), "start with profile 1");

$tfv->profile({ required => ['bar'] });
ok(!$tfv->check('foo' => 1),  "switch to profile 2");
ok($tfv->check('bar' => 1),   "switch to profile 2 (correct input as hash)");
ok($tfv->check({'bar' => 1}), "switch to profile 2 (correct input as hashref)");

# test check() with profile() - it should not permanently set the profile
$tfv->profile({ required => ['foo'] });
ok(!$tfv->check({ 'foo' => 1 }, { required => ['bubba'] }), 'temporary new profile via check');
ok($tfv->check({ 'foo' => 1 }), 'after check, old profile is restored');


# test new() - can we do the same stuff here as we can do with DFV?
# here we test with and without the 'trim' filter

my %input = (
   'foo' => ' test ',
);
my %profile = (
   'required' => ['foo'],
);

my $tfv_normal = Test::FormValidator->new;

my $results = $tfv_normal->check(\%input, \%profile);
is($results->valid->{'foo'}, $input{'foo'}, "tfv_normal (value is unchanged)");

my $tfv_trim = Test::FormValidator->new({}, {
    'filters' => 'trim',
});

$results = $tfv_trim->check(\%input, \%profile);
is($results->valid->{'foo'}, 'test', "tfv_trim (value has whitespace removed)");

