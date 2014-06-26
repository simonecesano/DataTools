use Getopt::Long::Descriptive;

$\ = "\n"; $, = "\t";

my ($opt, $usage) =
    describe_options(
		     'hietab.pl %o <some-arg> - create hierarchical tables',
		     [ "columns|c=i", "columns that need to be summarized", { default => 1 } ],
		     [ "headers|d=i", "print headers every x lines" ],
		     [],
		     [ 'verbose|v',  "print extra stuff"            ],
		     [ 'help|h',       "print usage message and exit" ],
		    );

print($usage->text), exit if $opt->help;


my @p;

my @head = split /\t/, <>; chop $head[-1];

my $headers_count = $opt->headers;
my $c = $opt->columns - 1;


print @head unless $opt->headers;

while (<>) {
    chop;
    my @d = split /\t/;
    my @o = @d;

    if ((defined $headers_count) && (($i++ % $headers_count) == 0)) { 
	print @head; print @d
    } else {
	for (0..$c) { if ($d[$_] ne $p[$_]) { last } else {  $d[$_] = "" } }
	print @d;
    }
    @p = @o;
}

