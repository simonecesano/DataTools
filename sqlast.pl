use Getopt::Long::Descriptive;
use Data::Dump qw/dump/;
use List::MoreUtils qw/uniq/;

use strict;

my ($opt, $usage) = describe_options(
				     "$0 %o <some-arg> - list and repeat sqlite commands ",
				     [ 'print|p', "print command"],
				     [ 'execute|x', "execute"],
				     [],
				     [ 'number|n=i', "use n-th command"],
				     [ 'all|a', "print all commands with numbers"],
				     [ 'beautify|B', "beautify"],
				     [],
				     [ 'verbose|v',  "print extra stuff"            ],
				     [ 'help|h',       "print usage message and exit" ],
				    );

print($usage->text), exit if $opt->help;

my $file = $ARGV[0];

$\ = "\n";

open my $sql, '<', "/Users/cesansim/.sqlite_history" || die "aahh";

my @sql = map { s/\s$//; s/\\040/ /g; $_ } grep { !/^\.q/ } <$sql>;
# shift @sql;

if ($opt->all) {
    my $i;
    do { printf "%03d. %s\n", $i++, $_ } for @sql;
    exit;
}


if ($opt->execute) {
    local $_ = $sql[-1];
    print "-- $_" if $opt->verbose; 

    $_ .= ";" unless /;\s*$/;  

    open SQLITE, " | sqlite3 \"$file\"";
    print SQLITE $_;
}

if ($opt->print) {
    if ($opt->beautify) {
	use SQL::Beautify;
	my $b = SQL::Beautify->new;
	$b->query($sql[-1]);
	print $b->beautify;    
    } else {
	print $sql[-1]
    }
    exit;
}

