use Text::Fuzzy;
use Data::Dump qw/dump/;
use File::Slurp qw/read_file/;
use Getopt::Long::Descriptive;

$\ = "\n"; $, = "\t";

my ($opt, $usage) =
    describe_options(
		     $0 . ' %o <words_file> <potential_matches_file>',
		     [],
		     [ 'verbose|v',  "print extra stuff"            ],
		     [ 'help|h',       "print usage message and exit" ],
		    );

print($usage->text), exit if $opt->help;

my @words   = map { chomp; $_ } read_file($ARGV[0]);
my @matches = map { chomp; $_ } read_file($ARGV[1]);

for (@words) {
    my $tf = Text::Fuzzy->new($_);
    my $i = $tf->nearest (\@matches);
    print $_, $matches[$i];
}
