#!/usr/bin/perl

use strict;
use warnings;

use JSON;
use LWP::UserAgent;

my $solr_port = 8983;
my $lsof_output = `lsof -i TCP:$solr_port -s TCP:LISTEN -n -P`;

unless ($lsof_output =~ qr/\*:$solr_port/) {
    die 'Solr is not listening on *:8983';
}

my $lwp = LWP::UserAgent->new;
my $cluster_status_url = "http://localhost:$solr_port/solr/admin/collections?action=CLUSTERSTATUS";
my $response = $lwp->get($cluster_status_url);

unless ($response->is_success) {
    die 'Bad HTTP response status from Solr: ' . $response->status_line;
}

my $response_content = decode_json($response->decoded_content);
my $response_status = $response_content->{responseHeader}{status};

if ($response_content->{responseHeader}{status} != 0) {
    die 'Bad responseHeader.status from Solr: ' . $response_content->{responseHeader}{status};
}

my $reponse_collections = $response_content->{cluster}{collections};
my @mbsssss_collections = qx( find /usr/lib/mbsssss -type f -name core.properties -exec dirname {} \\; | xargs -I {} basename {} );
chomp(@mbsssss_collections);

for my $collection (@mbsssss_collections) {
    unless (exists $reponse_collections->{$collection}) {
        die "Collection '$collection' not found in CLUSTERSTATUS\n";
    }
    my $shards = $reponse_collections->{$collection}{shards};
    for my $shard (keys %$shards) {
        my $replicas = $shards->{$shard}{replicas};
        for my $replica (keys %$replicas) {
            my $state = $replicas->{$replica}{state};
            if ($state ne 'active') {
                die "Collection '$collection' not healthy (shard $shard, replica $replica, state $state)";
            }
        }
    }
}

exit 0;
