#!/usr/bin/env perl6
use IO::Socket::Async::SSL;

sub MAIN() {
    my $counter = 0;
    react {
        my %ssl-config =
                certificate-file => '/tmp/server-crt.pem',
                private-key-file => '/tmp/server-key.pem';
        whenever IO::Socket::Async::SSL.listen('localhost', 4433, |%ssl-config) -> $conn {
            say "Got conn!";
            await $conn.print(get_fortune());
            #await $conn.print(get_fortune());
            whenever $conn -> $line {
                say $line;
                if $line.contains("SENDING") {
                    await $conn.print("340 OK {$counter++}\r\n");
                } else {
                    await $conn.print("200 OK\r\n");
                    #$conn.close;
                }
            }
        }
    }
}

sub get_fortune(-->Str) {
    return run('fortune', :out).out.slurp(:close)~"200 OK\r\n";
}
