
multi MAIN() {
    my $channel = Channel.new();
    $channel.send($_) for ^29;
    $channel.close();
    my @promises = do for ^4 -> $consumer {
        start {

            my $p = IO::Socket::Async::SSL.connect('localhost', 4433, insecure => True);
            my $conn;
            # Read the MOTD
            await $p.then: -> $prom {
                $conn = $prom.result;
                react whenever $conn.Supply.lines -> $line {
                    say "[$consumer] Intro: $line";
                    done if $line ~~ /^200/;
                }
            }

            # Start consuming
            $channel.Supply.tap(-> $val {
                await $conn.print("SENDING\r\n").then: -> $promise {
                    react whenever $conn.Supply -> $line {
                        print "[$consumer] $line";
                        if $line ~~ /^340/ {
                            await $conn.print("[$consumer]: value $val\r\n");
                        } else {
                            done;
                        }

                    }
                }
            }, done=>{say "[$consumer] DONE!";});
            say "[$consumer] TAP DONE!";
        }
    }

    await Promise.allof(@promises);

    say $_.status for @promises;
}

