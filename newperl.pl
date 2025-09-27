#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use feature 'say';
use File::Basename;

sub usage {
    my ($exit) = @_;
    my $prog = basename($0);

    say "usage: $prog <name>\n";
    say "create a basic perl script template";
    exit $exit;
}

my $name = shift or usage(1);
usage(0) if lc $name eq '-h' || lc $name eq '--help';
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