if (-e $ARGV[0]) {
    local $/;
    open my $fh, '<', $file or die "can't open: $!";
    $_ = <$fh>;
} else {
    local $/;
    $_ = <>;
    close STDIN;
}

s/\}\n\{/},\n{/gm;

printf "[%s]\n", $_;
