use strict;
use warnings;
use FindBin;
use lib 'lib';
use lib "$FindBin::Bin/../lib";
use ReplaceStatement;

# perl samples/replace-add-with-two-arguments-to-reverse-add.pl samples/in.pl samples/out.pl

my $transform = ReplaceStatement->new(
    rules => [
        {
            pattern => ['add', '(', qr/.*/, ',', qr/.*/, ')'],
            apply => sub {
                my ($tokens) = @_;
                my $method = $tokens->[0];
                my $arg1 = $tokens->[2];
                my $arg2 = $tokens->[4];

                return "reverse_$method($arg2, $arg1)";
            },
        },
    ],
);

$transform->file(@ARGV);
