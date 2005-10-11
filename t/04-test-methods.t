
use strict;

use Test::Builder::Tester 'tests' => 15;
use Test::More;
use Data::FormValidator::Constraints qw(:closures);
use Test::FormValidator;

my $tfv = Test::FormValidator->new;

$tfv->profile({
            required => [ qw(
                name
                email
                pass1
                pass2
            ) ],
            optional => [ qw(
                newsletter
            ) ],
            dependencies => {
                pass1 => 'pass2',
            },
            constraint_methods => {
                # passwords must be longer than 5 characters
                pass1 => [
                    sub {
                        my ($dfv, $val) = @_;
                        $dfv->name_this('too_short');
                        return $val if (length $val) > 5;
                        return;
                    },
                    # passwords must contain both letters and numbers
                    sub {
                        my ($dfv, $val) = @_;
                        $dfv->name_this('need_alpha_num');
                        return $val if $val =~ /\d/ and $val =~ /[[:alpha:]]/;
                        return;
                    },
                ],
                # passwords must match
                pass2 => sub {
                    my ($dfv, $val) = @_;
                    $dfv->name_this('mismatch');
                    my $data = $dfv->get_input_data('as_hashref' => 1);
                    return $data->{'pass1'} if ($data->{'pass1'} || '') eq ($data->{'pass2'} || '');
                    return;
                },
                # email must be valid
                email => email(),
            },
});

# Test Missing
$tfv->check;  # missing name, email, pass1, pass2

test_out("ok 1 - missing fields");
$tfv->missing_ok([qw(name email pass1 pass2)], "missing fields");
test_test("missing_ok - caught passed test of missing fields");

test_out("not ok 1 - missing fields");
$tfv->missing_ok([qw(name email pass2)], "missing fields");
test_test(name => "missing_ok - caught failed test of missing fields", skip_err => 1);

test_out("not ok 1 - missing fields");
$tfv->missing_ok([qw(name email pass2)], "missing fields");
test_diag(split /[\r\n]+/, $tfv->_results_diagnostics);
test_fail(-2);
test_test(name => "missing_ok - caught failed test of missing fields (diagnostics)");

# Test Missing with none missing
$tfv->check(
    name  => 'test',
    email => 'test@example.com',
    pass1 => 'seekrit123',
    pass2 => 'seekrit123',
);
test_out("ok 1 - no missing fields");
$tfv->missing_ok([], "no missing fields");
test_test("missing_ok - caught passed test of valid input");

# Test Invalid (array) with none invalid
$tfv->check(
    name  => 'test',
    email => 'test@example.com',
    pass1 => 'seekrit123',
    pass2 => 'seekrit123',
);
test_out("ok 1 - no invalid fields");
$tfv->invalid_ok([], "no invalid fields");
test_test("invalid_ok (array) - caught passed test of valid input");


# Test Invalid (array) with bad email address and too short password
$tfv->check(
    name  => 'test',
    email => 'test-at-example.com',
    pass1 => 'foo',
    pass2 => 'foo',
);
test_out("ok 1 - invalid fields");
$tfv->invalid_ok([qw(email pass1)], "invalid fields");
test_test("invalid_ok (array) - caught passed test of invalid input");


# Test Invalid (hash) with none invalid
$tfv->check(
    name  => 'test',
    email => 'test@example.com',
    pass1 => 'seekrit123',
    pass2 => 'seekrit123',
);
test_out("ok 1 - no invalid fields");
$tfv->invalid_ok({}, "no invalid fields");
test_test("invalid_ok (hash) - caught passed test of valid input");

# Test Invalid (hash) with bad email address and too short password
$tfv->check(
    name  => 'test',
    email => 'test-at-example.com',
    pass1 => 'foo1',
    pass2 => 'foo1',
);
test_out("ok 1 - invalid fields");
$tfv->invalid_ok({
    email => 'email',
    pass1 => 'too_short',
}, "invalid fields");
test_test("invalid_ok (hash) - caught passed test of invalid input");

# Test Invalid (hash) with bad email address and too short password, but missing the password constraint
test_out("not ok 1 - invalid fields");
$tfv->invalid_ok({
    email => 'email',
}, "invalid fields");
test_test(name => "invalid_ok (hash) - caught failed test of invalid input", skip_err => 1);

# Test Invalid (hash) with bad email address and too short password, and non-alpha-num password,
# but missing the non-alpha-num password constraint
$tfv->check(
    name  => 'test',
    email => 'test-at-example.com',
    pass1 => 'foo',
    pass2 => 'foo',
);
test_out("not ok 1 - invalid fields");
$tfv->invalid_ok({
    email => 'email',
    pass1  => 'too_short',
}, "invalid fields");
test_test(name => "invalid_ok (hash) - caught failed test of invalid input (didn't catch all constrainsts)", skip_err => 1);

# Test Invalid (hash) with bad email address and too short password, and non-alpha-num password,
# and catching all constraints properly
$tfv->check(
    name  => 'test',
    email => 'test-at-example.com',
    pass1 => 'foo',
    pass2 => 'foo',
);
test_out("ok 1 - invalid fields");
$tfv->invalid_ok({
    email => 'email',
    pass1  => ['too_short', 'need_alpha_num'],
}, "invalid fields");
test_test(name => "invalid_ok (hash) - caught passing test of invalid input", skip_err => 1);


# Test Invalid (hash) with bad email address and too short password, and non-alpha-num password,
# and catching all constraints properly
# - add pass2 mismatch
# - reversed order of pass1 constraints
$tfv->check(
    name  => 'test',
    email => 'test-at-example.com',
    pass1 => 'foo',
    pass2 => 'bar',
);
test_out("ok 1 - invalid fields");
$tfv->invalid_ok({
    email => ['email'],
    pass1  => ['need_alpha_num', 'too_short'],
    pass2  => 'mismatch',
}, "invalid fields");
test_test(name => "invalid_ok (hash) - caught passing test of invalid input (added pass2 mismatch, changed order of pass1 constraints)", skip_err => 1);


# Test Valid with none invalid
$tfv->check(
    name  => 'test',
    email => 'test@example.com',
    pass1 => 'seekrit123',
    pass2 => 'seekrit123',
);
test_out("ok 1 - all fields valid");
$tfv->valid_ok([qw(name pass1 email pass2)], "all fields valid");
test_test("valid_ok - caught passed test of valid input");


# Test Valid with bad email address and too short password
$tfv->check(
    name  => 'test',
    email => 'test-at-example.com',
    pass1 => 'foo',
    pass2 => 'foo',
);
test_out("ok 1 - some valid fields");
$tfv->valid_ok([qw(name pass2)], "some valid fields");
test_test("valid_ok - caught passed test of invalid input");

# Test Valid fail by not supplying all valid
$tfv->check(
    name  => 'test',
    email => 'test-at-example.com',
    pass1 => 'foo',
    pass2 => 'foo',
);
test_out("not ok 1 - some valid fields");
$tfv->valid_ok([qw(name)], "some valid fields");
test_test(name => "valid_ok - caught failed test - did not test for all valid fields", skip_err => 1);

