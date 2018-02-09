# Copyright (c) 2018 Todd T. Fries <todd@fries.net>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

package WebService::BleuTrade;
use Moose;
with 'WebService::Client';

use Crypt::Mac::HMAC qw(hmac hmac_hex);
use Function::Parameters;
use HTTP::Request::Common qw(DELETE GET POST PUT);
use Time::HiRes qw(time);

has api_key => (
    is       => 'ro',
    required => 0,
);

has api_secret => (
    is       => 'ro',
    required => 0,
);

has '+base_url' => (
    is      => 'ro',
    default => 'https://bleutrade.com/api/v2',
    #help   => 'https://bleutrade.com/help/API',
);

sub BUILD {
    my ($self) = @_;
    if (defined($self->api_key)) {
    	$self->ua->default_header(':ACCESS_KEY' => $self->api_key);
    }
}

around req => fun($orig, $self, $req, @rest) {
    if (defined($self->api_key)) {
    	my $nonce = time();
	my $uri = $req->uri;
	if ($uri =~ /\?/) {
		$uri .= "&";
	} else {
		$uri .= "?";
	}
	$uri .= "apikey=".$self->api_key;
	$uri .= "&nonce=".$nonce;
	$req->uri($uri);
    	my $signature = hmac_hex('SHA512', $req->uri, $self->api_secret);
    	$req->header('apisign:' => $signature);
    }
    return $self->$orig($req, @rest);
};

method getmarkets { $self->get('/public/getmarkets') };

method getmarketsummaries { $self->get('/public/getmarketsummaries') };

method dcrbtc { $self->get('/public/getticker?market=DCR_BTC') };

# ABSTRACT: BlueTrade (https://bleutrade.com) API bindings

=head1 SYNOPSIS

    use WebService::BleuTrade;

    my $bt = WebService::BlueTrade->new(
        api_key    => 'API_KEY',
        api_secret => 'API_SECRET',
        logger     => Log::Tiny->new('/tmp/coin.log'), # optional
    );
    my $markets = $bt->getmarkets();
    my $dcrbtc  = $bt->dcrbtc();

=head1 METHODS

=head2 getmarkets

    getmarkets()

Returns the market list.

=head2 dcrbtc

    dcrbtc()

Returns the pricing for the DCR/BTC exchange.

=cut

1;
