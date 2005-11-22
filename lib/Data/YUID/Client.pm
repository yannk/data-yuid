# $Id$

package Data::YUID::Client;
use strict;

use fields qw( servers );
use Carp;
use IO::Socket::INET;
use URI::Escape ();

use constant DEFAULT_PORT => 9001;

my %sock_cache = ();

sub new {
    my Data::YUID::Client $client = shift;
    my %args = @_;
    $client = fields::new($client) unless ref $client;

    croak "servers must be an arrayref if specified"
        unless !exists $args{servers} || ref $args{servers} eq 'ARRAY';
    $client->{servers} = $args{servers} || [];

    $client->connect_to_servers;
    $client;
}

sub get_id {
    my Data::YUID::Client $client = shift;
    my($ns) = @_;
    my $sock = $client->get_sock;
    $sock->printf("getid ns=%s\r\n", URI::Escape::uri_escape($ns || ''));
    chomp(my $res = <$sock>);
    my($id) = $res =~ /^id\s+(\d+)/i;
    croak "$res\n" unless $id;
    $id;
}

sub connect_to_servers {
    my Data::YUID::Client $client = shift;
    for my $host (@{ $client->{servers} }) {
        my $sock = $client->connect_to_server($host)
            or next;
        $sock_cache{$host} = $sock;
    }
}

sub connect_to_server {
    my Data::YUID::Client $client = shift;
    my($host) = @_;
    my($ip, $port) = split /:/, $host;
    $port ||= DEFAULT_PORT;
    my $sock = IO::Socket::INET->new(
            PeerAddr        => $ip,
            PeerPort        => $port,
            Proto           => 'tcp',
            Type            => SOCK_STREAM,
            ReuseAddr       => 1,
            Blocking        => 1,
        ) or return;
    $sock;
}

sub get_sock {
    my Data::YUID::Client $client = shift;
    my @hosts = keys %sock_cache;
    my $host = $hosts[ int rand @hosts ];
    $sock_cache{$host};
}

1;
__END__

=head1 NAME

Data::YUID::Client - Client for distributed YUID generation

=head1 SYNOPSIS

    use Data::YUID::Client;
    my $client = Data::YUID::Client->new(
            servers => [
                '192.168.100.4:11001',
                '192.168.100.5:11001',
            ],
        );
    my $id = $client->get_id;

=head1 DESCRIPTION

I<Data::YUID::Client> is a client for the client/server protocol used to
generate distributed unique IDs. F<bin/yuidd> implements the server portion
of the protocol.

=head1 USAGE

=head2 Data::YUID::Client->new(%param)

Creates a new client object, initialized with I<%param>, and returns the
new object.

I<%param> can contain:

=over 4

=item * servers

A reference to a list of server addresses, in I<host:port> notation. These
should point to the locations of servers running the F<yuidd> server using
the client/server protocol for ID generation.

I<new> will attempt to connect to each of the servers and will cache the
connections internally.

=back

=head2 $client->get_id([ $namespace ])

Obtains a unique ID from one of the servers, in the optional namespace
I<$namespace>.

=head1 AUTHOR & COPYRIGHT

Please see the I<Data::YUID> manpage for author, copyright, and license
information.

=cut
