use Template;
use File::Slurp;
use Text::CSV_XS;
use Data::Dump qw/dump/;
use Path::Class;

use Getopt::Long::Descriptive;

$\ = "\n"; $, = "\t";

my ($opt, $usage) =
    describe_options(
		     'xltoperl %o <data_file> <template_file>',
		     [ 'single_file|S', 'one output file per element' ],
		     [ 'directory|d=s', "output directory"      ],
		     [ 'file_name|f=s', "filename template" ],
		     [],
		     [ 'verbose|v',  "print extra stuff"            ],
		     [ 'help',       "print usage message and exit" ],
		    );

# my $d = dir($root, $dir, $artist, $album);
#     my $f = file($root, $dir, $artist, $album, (sprintf '%02d-%s%s', $track, $title, $type));
#     print "$_ $f";
#     $d->mkpath;


print($usage->text), exit if $opt->help;

my $data     = do $ARGV[0];
my $template = read_file($ARGV[1]);
my $tt = Template->new({
    EVAL_PERL => 1,
});

$ARGV[1] =~ s/(\.\w{1,4})//; $ext = $1;
my @dir = split '/', $opt->file_name; 
my $depth = -1 + scalar @dir;

if ($opt->single_file) {
    for (@$data) {
	my @dir = @{$_}{@dir};
	for (@dir) { s/^\W+|\W+$//g; s/\W+/_/g; s/^\s+|\s+$//g; $_ = lc };
	$dir[-1] .= $ext;

	if ($opt->directory) { unshift @dir, $opt->directory };


	#my $file = $_->{file};
	$file = file(@dir);

	print STDERR $file;
	print dir(@dir[0..$depth]);
	dir(@dir[0..$depth])->mkpath;
	my $fh = $file->openw()
	  || die;
	$tt->process(\$template, $_, $fh)
	    || die $tt->error(), "\n";
    }
} else {
    $tt->process(\$template, { data => $data } )
	|| die $tt->error(), "\n";
}

