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
    if (defined($self->api_key) && ! ($req->uri =~ /\/public\//)) {
	#printf "req->%s .. api_key = '%s', api_secret = '%s'\n", $orig,
	#	$self->api_key, $self->api_secret;
    	my $nonce = time();
	my $uri = $req->uri;
	if ($uri =~ /\?/) {
		$uri .= "&";
	} else {
		$uri .= "?";
	}
	$uri .= "apikey=".$self->api_key;
	$uri .= "&nonce=".$nonce;
	#printf "req->%s .. uri = '%s'\n", $uri;
	$req->uri($uri);
    	my $signature;
	eval {
		$signature = hmac_hex('SHA512',
			$self->api_secret,
			$req->uri,
		);
	};
	if ($@) {
		print "around req(..): $@\n";
		return undef;
	}
	#printf "around req(..): apisign = '%s'\n", $signature;
    	$req->header('apisign' => $signature);
    }
    return $self->$orig($req, @rest);
};

# Public info

method getcurrencies { $self->get('/public/getcurrencies') };

method getmarkets { $self->get('/public/getmarkets') };

method getticker($market) { $self->get("/getticker?market=${market}") };

method getmarketsummaries { $self->get('/public/getmarketsummaries') };

method getmarketsummary($market) {
	$self->get("/public/getmarketsummary?market=${market}");
};

method getorderbook($market, $type, $depth) {
	my $call = "/public/getorderbook?market=${market}&type=${type}";
	if (defined($depth)) {
		$call .= "&depth=${depth}";
	}
	#print "getorderbook call=$call\n";
	$self->get($call);
}

method getmarkethistory($market, $count) {
	my $call = "/public/getmarkethistory?market=${market}";
	if (defined($count)) {
		$call .= "&count=${count}";
	}
	$self->get($call);
}

method getcandles($market, $period, $count, $lasthours) {
	my $call = "/public/getcandles?market=${market}";
	$call .= "&period=${period}";
	$call .= "&count=${count}";
	$call .= "&lasthours=${lasthours}";
	$self->get($call);
}

# Private info

method getbalances { $self->get('/account/getbalances') };

method getorders($market, $ostat, $otype, $depth) {
	if (!defined($market)) {
		$market = "ALL";
	}
	if (!defined($ostat)) {
		$ostat = "ALL";
	}
	if (!defined($otype)) {
		$otype = "ALL";
	}
	if (!defined($depth)) {
		$depth = 500;
	}
	my $uri = '/account/getorders';
	$uri .= "?market=${market}";
	$uri .= "&orderstatus=${ostat}";
	$uri .= "&ordertype=${otype}";
	$uri .= "&depth=500";
	#printf "getorders: uri='%s'\n", $uri;
	$self->get($uri);
};

method getorderhistory($oid) {
	$self->get('/account/getorderhistory?orderid=${oid}')
};

method getwithdrawhistory { $self->get('/account/getwithdrawhistory') };

method getdepositaddress($c) {
	$self->get("/account/getdepositaddress?currency=${c}")
};

# pseudo methods that are munging of hardcoded parameters and bt api

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
