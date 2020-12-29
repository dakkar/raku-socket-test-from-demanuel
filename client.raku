#!/usr/bin/env raku

sub one-client($channel,$consumer) {

    CATCH { say $_ };

    my $conn = await IO::Socket::Async.connect('localhost', 4433);
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
            await $conn.print("SENDING\r\n");
            say "[$consumer] sent";

            react {
                whenever $conn-supply -> $line {
                    print "[$consumer] <- $line";
                    if $line ~~ /^340/ {
                        say "[$consumer] -> $val";
                        await $conn.print("[$consumer]: value $val\r\n");
                        say "[$consumer] sent";
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

