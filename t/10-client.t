# $Id$

use strict;
use Data::YUID::Client;
use File::Spec;
use FindBin qw( $Bin );
use IO::Socket::INET;
use Test::More tests => 3;

use constant PORT => 11000;
our %Children;

END { kill_children() }

start_server(PORT);
start_server(PORT + 1);

## Sleep, wait for servers to start up before connecting workers.
wait_for_port(PORT);
wait_for_port(PORT + 1);

my $client = Data::YUID::Client->new(
        servers => [ map '127.0.0.1:' . $_, PORT, PORT + 1 ],
);
isa_ok($client, 'Data::YUID::Client');

my $id1 = $client->get_id;
ok($id1);

my $id2 = $client->get_id;
isnt($id1, $id2);

sub start_server {
    my($port) = @_;
    my $server = File::Spec->catfile($Bin, '..', 'bin', 'yuidd');
    my $pid = start_child([ $server, '-p', $port ]);
    $Children{$pid} = 'S';
}

sub start_child {
    my($cmd) = @_;
    my $pid = fork();
    die $! unless defined $pid;
    unless ($pid) {
        exec 'perl', '-Iblib/lib', '-Ilib', @$cmd or die $!;
    }
    $pid;
}

sub kill_children {
    kill INT => keys %Children;
}

sub wait_for_port {
    my($port) = @_;
    my $start = time;
    while (1) {
        my $sock = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port");
        return 1 if $sock;
        select undef, undef, undef, 0.25;
        die "Timeout waiting for port $port to startup" if time > $start + 5;
    }
}
