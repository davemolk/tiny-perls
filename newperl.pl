#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use feature 'say';

sub usage {
    my ($exit) = @_;
    say << "USAGE";
usage: $0 <name>
create a basic perl script template
USAGE
    exit $exit;
}

my $name = shift or usage(1);
$name =~ s/\.pl$//i;

my @lines = (
    "#!/usr/bin/perl",
    "",
    "use strict;",
    "use warnings;",
    "use autodie;",
    "use feature 'say';",
);

open(my $fh, '>', "$name.pl");
for my $line (@lines) {
    say $fh $line;
}
close $fh;