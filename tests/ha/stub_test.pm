# SUSE's openQA tests
#
# Copyright 2019 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: stub test for a cluster
# Maintainer: QE-SAP <qe-sap@suse.de>

use base 'opensusebasetest';
use strict;
use warnings;
use testapi;
use lockapi;
use version_utils qw(is_sle);
use hacluster;

sub run {
    my $cluster_name = get_cluster_name;

    # We can sync the execution of the test module in all nodes by calling barrier_wait
    # barrier_wait("SOME_BARRIER_NAME");
    # Example: barrier_wait("SBD_DONE_$cluster_name");
    # Barriers need to be initialized in the parent job. See tests/ha/barrier_init.pm

    # This runs in all nodes
    assert_script_run 'crm status';

    # This also runs in all nodes, but we save the output to a variable and print it
    my $out = script_output $crm_mon_cmd;
    record_info 'crm_mon', $out;
    diag "crm_mon output => $out";

    # Run commands in different nodes
    if (is_node(1)) {
        # This will run only in node 1
        assert_script_run 'clear; echo "This runs only in node 1"';
        record_info 'Node 1 - Info', 'This is recorded only in job for node 1';
    }
    else {
        # This will run in all other nodes
        assert_script_run 'clear; echo "This runs in all nodes except node 1"';
        record_info 'Node N - Info', 'This is recorded in all nodes, except node 1';
    }

    # Run a command only in a node at once.
    # We reuse the csync2 lock. Another lock called cluster_restart also exists.
    # More locks can be created in tests/ha/barrier_init.pm
    mutex_lock 'csync2';
    record_info 'Date - ', scalar(localtime());
    sleep 60;
    mutex_unlock 'csync2';

    # Record cluster state
    save_state;
}

1;
