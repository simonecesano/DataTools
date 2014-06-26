use Data::Dump qw/dump/;
use List::MoreUtils qw/all/;
use List::Util qw/max/;

$\ = "\n"; $, = "\t";

my $data = do $ARGV[0];
my $t;

my @cols = @{ shift @$data };

for my $d (@$data) { for (@cols) { push @{$t->{$_}}, $d->{$_} } }

my @r;
my $l = 2 + max map { length $_ } @cols;

for (@cols) {
    my @d = @{$t->{$_}};
    if (all { /^\d+$/ } @d)        { push @r, sprintf "%-${l}s %s", $_, 'INTEGER'; next }
    if (all { /^\d+\.*\d*$/ } @d)   { push @r, sprintf "%-${l}s %s", $_, 'FLOAT'; next }
    push @r, sprintf "%-${l}s %s(%d)", $_, 'VARCHAR', (max map { length $_ } @d);
}

print join ",\n", map { "    $_" } @r;
