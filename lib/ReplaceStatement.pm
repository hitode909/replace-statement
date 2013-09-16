package ReplaceStatement;
use strict;
use warnings;
use parent qw(PPI::Transform);
use List::MoreUtils qw(any);

sub new {
    my ($class, %args) = @_;

    $class->SUPER::new(
        rules => $args{rules},
        documents => [],
    );
}

sub file {
    my ($self, $input, $output) = @_;

    $self->SUPER::file($input, $output);
    $self->{documents} = [];
}

sub document {
    my ($self, $document) = @_;

    my $changed = 0;

    my $tokens = $document->find('PPI::Token');
    for my $token (@$tokens) {
        my ($rule, $matched);
        for (@{$self->{rules}}) {
            $rule = $_;
            $matched = $self->_match($token, $rule->{pattern});
            last if $matched;
        }
        next unless $matched;

        # statementを差し替える
        # statement → (前半 + マッチ箇所を差し替えた内容 + 後半)

        my $statement = $matched->[0]->statement;

        my $pre_content = '';
        my $suf_content = '';
        my $begin_found;
        my $end_found;
        for my $token (@{$statement->find('PPI::Token')}) {
            if (!$begin_found) {
                if ($token == $matched->[0]) {
                    $begin_found++;
                } else {
                    $pre_content .= $token;
                }
            } elsif (!$end_found) {
                if ($token == $matched->[-1]) {
                    $end_found++;
                }
            } else {
                $suf_content .= $token;
            }
        }

        my $nonwhite = [ grep { ! $_->isa('PPI::Token::Whitespace') } @$matched ];
        my $replaced_content = $rule->{apply}->($nonwhite);
        chomp($replaced_content);

        my $new_content = $pre_content . $replaced_content . $suf_content;

        # 置換後に改行があるとき，statement開始時のインデントに揃える
        if ($new_content =~ /\n/) {
            my $indent = $statement->previous_token;
            last unless $indent->isa('PPI::Token::Whitespace');
            $indent =~ s/\n//g;
            $new_content =~ s/\n/\n$indent/gm;
        }

        my $new_doc = PPI::Document->new(\$new_content);

        # XXX: 参照を残しておかないとこのループ抜けたときに消える
        push @{$self->{documents}}, $new_doc;

        my $new_statement = $new_doc->find('PPI::Statement')->[0];

        $statement->insert_before($new_statement);
        $statement->remove;
        $changed++;
        last;
    }
    if ($changed) {
        # 書き換えたのでもう1回最初から見る
        # 2回マッチするようなルールがあれば終わらないので気をつける
        $self->document($document);
    }
    $changed;
}

# args:
#   token: 始点
#   pattern: [ (文字列 or 正規表現) ]
# returns:
#   [ 始点〜matchした区間のtoken ]
sub _match {
    my ($self, $token, $pattern) = @_;
    return if $token->isa('PPI::Token::Whitespace');

    my $result = [];
    for my $pattern_token (@$pattern) {
        while ($token && $token->isa('PPI::Token::Whitespace')) {
            push @$result, $token;
            $token = $token->next_token;
        }
        return unless $token;
        return unless defined $token->content;
        return unless $token->content ~~ $pattern_token;
        push @$result, $token;
        $token = $token->next_token;
    }
    return $result;
}

1;
