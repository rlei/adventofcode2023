#!/usr/bin/env perl
use feature qw(say);
use List::Util qw/sum/;

my $total = 0;
while (<>) {
    my ($card, $nums) = split(':');
    my ($winningNumbersStr, $numbersStr) = split("\\|", $nums);

    my %winningNumbers = map { $_ => 1 } split(" ", $winningNumbersStr);
    my @numbers = split(" ", $numbersStr);

    my $found = sum(map {exists $winningNumbers{$_} ? 1 : 0} @numbers);
    # say $found;
    $total += $found > 0 ? 1 << ($found - 1) : 0;
}
say $total
