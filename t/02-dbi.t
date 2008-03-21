# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 02-dbi.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
my $tests;
BEGIN { $tests = 10; plan tests => $tests };

my $dbh;
eval 'use DBI; $dbh = DBI->connect("dbi:DBM:");';
unless($dbh) {
	for(1 .. $tests) {
		skip("Skip DBI, DBD::DBM not available ($@)");
	}
} else {

$dbh->{RaiseError} = 1;
# Set up environment
$dbh->do("DROP TABLE IF EXISTS fruit")
	or die($dbh->errstr());
$dbh->do("CREATE TABLE fruit (dKey INT, dVal VARCHAR(10))")
	or die($dbh->errstr());

ok(1); # If we made it this far, we're ok.

#########################

my $a = 1;
my $b = 2;
my $c = 3;
my $d = 'oranges';
my $e = q('";);
my $f = 'to delete';
my $g = 'apples';

{
use DBIx::InterpolationBinding;

# Try an insert
ok($dbh->execute("INSERT INTO fruit VALUES ($a,$d)"));
ok($dbh->execute("INSERT INTO fruit VALUES ($b,$e)"));
ok($dbh->execute("INSERT INTO fruit VALUES ($c,$f)"));

# And an update
$sth = $dbh->execute("UPDATE fruit SET dVal=$g WHERE dKey=$b");
ok($sth and $sth->rows == 1);
$sth->finish if $sth;

# And a delete
$sth = $dbh->execute("DELETE FROM fruit WHERE dVal=$f");
ok($sth and $sth->rows == 1);

# Try a select
my $row;
$sth = $dbh->execute("SELECT * FROM fruit WHERE dVal = $g");
ok($sth and $sth->rows == 1 and $row = $sth->fetchrow_hashref and
   $row->{dKey} eq $b and $row->{dVal} eq $g);
$sth->finish if $sth;

# And a loop
foreach my $type ($d, $g) {
	$sth = $dbh->execute("SELECT * FROM fruit WHERE dVal = $type");
	ok($sth and $sth->rows == 1 and $row = $sth->fetchrow_hashref and
		$row->{dVal} eq $type);
}

}

# Can't work outside scope? - the eval should fail as the string isn't
# overloaded.
eval {
	$dbh->{PrintError} = 0;
	my $sth = $dbh->execute("SELECT * FROM fruit WHERE dVal = $c");
	$sth->finish;
};
ok($@);

# Cleanup
$dbh->do("DROP TABLE fruit");

}
