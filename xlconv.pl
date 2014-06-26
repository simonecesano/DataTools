use Getopt::Long::Descriptive;
use File::Spec;
use Data::Dump qw/dump/;

$\ = "\n";

my ($opt, $usage) = 
    describe_options
    (
     "$0 %o <some-arg>",
     [ 'skip|s=i', "lines to skip at top"                  ],
     [ 'convert|c',   "convert file - do not send to STDOUT" ],
     [ 'clobber|C',   "clobber existing files" ],
     [],
     [ 'raw|R',   "print raw ssconvert output" ],
     [ 'dump|D',   "print perl data structure" ],
     [],
     [ 'csv|V',   "handle as CSV (for nasty cases)" ],
     [ 'here|H',   "output file in current directory" ],
     [],
     [ 'name|n',   "add name as first column" ],
     [ 'path|p',   "add path as first column" ],
     [ 'data|d',   "add data at beginning"],
     [],
     [ 'verbose|v',  "print extra stuff"            ],
     [ 'help|h',       "print usage message and exit" ],
    );

print($usage->text), exit if $opt->help;

my $file = $ARGV[0];

printf STDERR "converting file %s\n", $file if $opt->verbose;

print($usage->text), exit unless -e $file;

my $abs_file = File::Spec->rel2abs($file);
my $file_name = [ File::Spec->splitdir($file) ]->[-1]; $file_name =~ s/\.xlsx*$//;

# print $abs_file; 
# print $file_name; 
# exit;

my $skip = $opt->skip;

if ($opt->convert) {
    my $out = $file;
    unless ($opt->here) {
	$out =~ s/\.xlsx*$/.txt/;
    } else {
	$out = "$file_name.txt"
    }

    unless ($opt->clobber) { die "File $out exists" if -e $out }

    print $out if $opt->verbose;
    open STDOUT, ">", $out || die "can't convert file";
}

my $print_sub;
$print_sub = sub { print join "\t", @_ };
$print_sub = sub { print join "\t", ($. == ($skip + 1) ? "file path" : $abs_file), @_ }  if $opt->path;
$print_sub = sub { print join "\t", ($. == ($skip + 1) ? "file name" : $file_name), @_ } if $opt->name;

my $dump_array = [];
$print_sub = sub { push @$dump_array, [ @_ ] } if $opt->dump;


if ($opt->raw) {
    open (my $xl, "ssconvert -O 'separator=:: eol=windows' -T Gnumeric_stf:stf_assistant \"$file\" fd://1 2> /dev/null | ");
    print while (<$xl>);
    exit;
}

if ($opt->csv) {
    use Text::CSV_XS;
    open (my $xl, "ssconvert -O 'separator=,' -T Gnumeric_stf:stf_assistant \"$file\" fd://1 2> /dev/null | ");

    my $i;
    my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });

    while (my $row = $csv->getline ($xl)) {
	next unless $i++ >= $skip;
	s/\r|\f|\n|\t/ /g for @$row;
	$print_sub->(@$row);
    }
    close $fh;
}


unless ($opt->csv) {
    open (my $xl, "ssconvert -O 'separator=:: eol=windows' -T Gnumeric_stf:stf_assistant \"$file\" fd://1 2> /dev/null | ");
    while (<$xl>) {
	chop;
	# s/\f/ /g;
	s/\t/ /g;
	s/::/\t/g;
	s/"//g;
	$print_sub->($_) if ($. > $skip);
    }
}

print dump $dump_array if $opt->dump;

__DATA__

OPTIONS FOR THE CONFIGURABLE TEXT (*.txt) EXPORTER
       sheet  Name  of  the  workbook sheet to operate on.  You can specify several sheets by repeating this option. If this option is not given the active sheet (i. e. the sheet that was active when the file was
              saved) is used.

       eol    End Of Line convention; how lines are terminated.  "unix" for linefeed, "mac" for carriage return; "windows" for carriage return plus linefeed.

       charset
              The character encoding of the output. Defaults to UTF-8.

       locale The locale to use for number and date formatting.  Defaults to the current locale as reported by locale(1).  Consult locale -a output for acceptable values.

       quote  The character or string used for quoting fields. Defaults to "\"" (quotation mark / double quote).

       separator
              The string used to separate fields. Defaults to space.

       format How cells should be formatted.  Acceptable values: "automatic" (apply automatic formatting; default), "raw" (output data raw, unformatted), or "preserve" (preserve the  formatting  from  the  source
              document).

              This deals with the difference between a cell's contents and the way those contents are formatted.

              Consider a cell in a Gnumeric input document that was input as "4/19/73" in a US locale, with a format set to "d-mmm-yyyy" and thus formatted as "19-Apr-1973".

              With the default format setting of "automatic" it will be output as "1973/04/19". With "preserve", the formatting will be preserved and it will be output as "19-Apr-1973". With "raw" it will be out-
              put as "26773" (Gnumeric's internal representation: days since an epoch).

       transliterate-mode
              How to handle unrepresentable characters (characters that cannot be represented in the chosen output character set).  Acceptable values: "transliterate", or "escape".

       quoting-mode
              When does data need to be quoted?  "never", "auto" (puts quotes where needed), or "always". Defaults to "never".

       quoting-on-whitespace
              Controls whether initial or terminal whitespace forces quoting. Defaults to TRUE.
