# ReplaceTokens

- A Perl Class for replace tokens of source code.
- Parse source with PPI -> match patterns -> replace tokens.
- This method is not good. It doesn't work when the order of keys are different, or the last colon is missing, etc.
- More better solution: [hitode909/rewrite-on-called](https://github.com/hitode909/rewrite-on-called)

## Examples

### Replacing method name

When you want to swap arguments of "add" and to rename it to "reverse_add",

```perl
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
```

#### Before

```perl
add(1, 2);
add(1, 2, 3);
```

#### After

```
reverse_add(2, 1);
add(1, 2, 3);
```

`['add', '(', qr/.*/, ',', qr/.*/, ')']` matches `add(1, 2)`, but doesn't match `add(1, 2, 3)`.

License
=======

MIT