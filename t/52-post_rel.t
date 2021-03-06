#!/usr/bin/env perl

use Test::Most;
use Plack::Test;
use Test::HTTP::Response;
use JSON;

use Devel::Dwarn;

use lib "t";
use TestDS;

my $test_key_string = "clients_dataservice";

my $app = require WebAPI::DBIC::WebApp;

note "===== Create item, with embedded items, by POST to set =====";

my $item;

test_psgi $app, sub {
    my $res = shift->(dsreq( POST => "/persons?rollback=1", [], {
        full_name => "$test_key_string test deleteme",
        deleted_at => "2000-01-01",
        _embedded => {
            type => {
                name => "test",
                description => "$test_key_string test deleteme",
            }
        }
    }));
    my ($location, $data) = dsresp_created_ok($res);
    like $location, qr{^/persons/\d+$}, 'returns reasonable Location';
    is $data, undef, 'returns no data'
        or diag $data;
};


test_psgi $app, sub {
    my $res = shift->(dsreq( POST => "/persons?rollback=1&prefetch=self", [], {
        full_name => "$test_key_string test deleteme",
        deleted_at => "2000-01-01",
        _embedded => {
            type => {
                name => "test",
                description => "$test_key_string test deleteme",
            }
        }
    }));
    my ($location, $data) = dsresp_created_ok($res);
    like $location, qr{^/persons/\d+$}, 'returns reasonable Location';

    is ref $data, 'HASH', 'return data';
    is $data->{full_name}, "$test_key_string test deleteme", 'has full_name';
    ok $data->{deleted_at}, 'has deleted_at';
    ok $data->{id}, 'has id assigned';
    ok $data->{type_id}, 'has type_id assigned';

    ok !exists $data->{_embedded}, 'has no _embedded';
};


test_psgi $app, sub {
    my $res = shift->(dsreq( POST => "/persons?rollback=1&prefetch=self,type", [], {
        full_name => "$test_key_string test deleteme",
        deleted_at => "2000-01-01",
        _embedded => {
            type => {
                name => "test",
                description => "$test_key_string test deleteme",
            }
        }
    }));
    my ($location, $data) = dsresp_created_ok($res);
    like $location, qr{^/persons/\d+$}, 'returns reasonable Location';

    is ref $data, 'HASH', 'return data';
    is $data->{full_name}, "$test_key_string test deleteme", 'has full_name';
    ok $data->{deleted_at}, 'has deleted_at';
    ok $data->{id}, 'has id assigned';
    ok $data->{type_id}, 'has type_id assigned';

    ok $data->{_embedded}, 'has _embedded';
    my $type = $data->{_embedded}{type};
    is ref $type, 'HASH', 'has _embedded type';
    is $type->{id}, $data->{type_id}, 'type_id matches';
    is $type->{name}, 'test', 'type name matches';
};

done_testing();
