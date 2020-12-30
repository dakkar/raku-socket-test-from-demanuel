#!/usr/bin/env raku
use IO::Socket::Async::SSL;

sub one-client($channel,$consumer) {

    CATCH { say $_ };

    my $conn = await IO::Socket::Async::SSL.connect('localhost', 4433, insecure => True);
    my $conn-supply = $conn.Supply;

    # Read the MOTD
    react {
        whenever $conn-supply.lines -> $line {
            say "[$consumer] Intro: $line";
            done if $line ~~ /^200/;
        }
    }

    react {
        whenever $channel -> $val {
            say "[$consumer] -> SENDING";
            $conn.print("SENDING\r\n").then: { say "[$consumer] sent" };

            react {
                whenever $conn-supply -> $line {
                    print "[$consumer] <- $line";
                    if $line ~~ /^340/ {
                        say "[$consumer] -> $val";
                        $conn.print("[$consumer]: value $val\r\n")
                        .then: { say "[$consumer] sent" };
                    } else {
                        say "[$consumer] done for $val";
                        done;
                    }
                }
            }
            LAST { say "[$consumer] done consuming channel" }
        }
    }
}

multi MAIN() {
    my $channel = Channel.new();
    $channel.send($_) for ^29;
    $channel.close();
    one-client($channel,0);
    exit;
    my @promises = (^1).map: -> $consumer {
        start one-client($channel,$consumer);
    }

    await Promise.allof(@promises);

    say $_.status for @promises;
}

