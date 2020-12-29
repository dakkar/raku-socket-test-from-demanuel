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
            await $conn.print("SENDING\r\n");

            react {
                whenever $conn-supply -> $line {
                    print "[$consumer] $line";
                    if $line ~~ /^340/ {
                        await $conn.print("[$consumer]: value $val\r\n");
                        done;
                    } else {
                        done;
                    }
                }
                LAST { say "[$consumer] DONE!" }
            }
        }
        LAST { say "[$consumer] TAP DONE!" }
    }
}

multi MAIN() {
    my $channel = Channel.new();
    $channel.send($_) for ^29;
    $channel.close();
    my @promises = do for ^4 -> $consumer {
        start { one-client($channel,$consumer) }
    }

    await Promise.allof(@promises);

    say $_.status for @promises;
}

