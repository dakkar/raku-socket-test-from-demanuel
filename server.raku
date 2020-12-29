#!/usr/bin/env raku

my $counter = 0;

sub serve-one($conn) {
    say "Got conn!";
    await $conn.print(get_fortune());

    react {
        whenever $conn.Supply.lines -> $line {
            say "<- $line";
            if $line.contains("SENDING") {
                say "-> $counter";
                await $conn.print("340 OK {$counter++}\r\n");
            } else {
                say "-> ok";
                await $conn.print("200 OK\r\n");
            }
            LAST { say "client disconnected" };
        }
    }
}

sub MAIN() {
    react {
        my %ssl-config =
                certificate-file => '/tmp/u/server-crt.pem',
                private-key-file => '/tmp/u/server-key.pem';
        whenever IO::Socket::Async.listen('localhost', 4433) -> $conn {
            start serve-one($conn);
        }
    }
}

sub get_fortune(-->Str) {
    return run('fortune', :out).out.slurp(:close)~"200 OK\r\n";
}
