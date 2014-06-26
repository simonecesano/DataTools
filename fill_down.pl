$\ = "\n"; $, = "\t";


while (<>) {
    chomp;
    my $i;
    my @d = split /\t/, $_;
    if ($. == 1) {
	$l = scalar @d;
	@p = @d;
    }

    next unless grep { !/^\s*$/ } @d; 

    for my $i (0..$l) { if ($d[$i] =~ /^\s*$/) { $d[$i] = $p[$i] } else { $p[$i] = $d[$i] } };
    print @d;
}
