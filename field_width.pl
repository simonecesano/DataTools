use XML::TreeBuilder;
use Data::Dump qw/dump/;
use List::Util qw/max/;

$\ = "\n"; $, = "\t";
my $file = $ARGV[0];

open INKSCAPE, "inkscape -S $file |";
while (<INKSCAPE>) {
    chop;
    my ($id, @pos) = split ',';
    $all->{$id} = $pos[2];
}

my $tree = XML::TreeBuilder->new({ 'NoExpand' => 0, 'ErrorContext' => 0 }); # empty tree
$tree->parse_file($file);

for ($tree->find('tspan')) {
    next unless $_->as_text =~ /\w/;
    my $id = $_->attr('id');
    $id =~ /(.+)_(\d+)$/; $grp = $1;
    # print $grp, $_->as_text, $all->{$id};
    push @{$lengths->{$grp}}, $all->{$id};

}

for (keys %$lengths) { $lengths->{$_} = max@{$lengths->{$_}} }

print dump $lengths;
