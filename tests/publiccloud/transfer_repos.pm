# SUSE's openQA tests
#
# Copyright 2019-2021 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Package: rsync
# Summary: Transfer repositories to the public cloud instasnce
#
# Maintainer: <qa-c@suse.de>

use Mojo::Base 'publiccloud::basetest';
use registration;
use warnings;
use testapi;
use strict;
use utils;
use publiccloud::ssh_interactive "select_host_console";

sub run {
    my ($self, $args) = @_;
    select_host_console();    # select console on the host, not the PC instance

    $self->{provider} = $args->{my_provider};    # required for cleanup

    my @instances = ();
    if ($args->{my_instance}) {
        push @instances, $args->{my_instance};
    }
    elsif ($args->{instances}) {
        @instances = @{$args->{instances}};
    }
    else {
        die 'No instance or list of instances received in %$args';
    }

    my @addons = split(/,/, get_var('SCC_ADDONS', ''));
    my $skip_mu = get_var('PUBLIC_CLOUD_SKIP_MU', 0);

    for my $instance (@instances) {
        my $remote = $instance->username . '@' . $instance->public_ip;

        # Trigger to skip the download to speed up verification runs
        if ($skip_mu) {
            record_info('Skip download', 'Skipping maintenance update download (triggered by setting)');
        } else {
            assert_script_run('du -sh ~/repos');
            my $timeout = 2400;

            $instance->retry_ssh_command(cmd => "which rsync || sudo zypper -n in rsync", timeout => 420, retry => 6, delay => 60);

            # Mitigate occasional CSP network problems (especially one CSP is prone to those issues!)
            # Delay of 2 minutes between the tries to give their network some time to recover after a failure
            script_retry("rsync --timeout=$timeout -uvahP -e ssh ~/repos '$remote:/tmp/repos'", timeout => $timeout + 10, retry => 3, delay => 120);
            $instance->ssh_assert_script_run("sudo find /tmp/repos/ -name *.repo -exec sed -i 's,http://,/tmp/repos/repos/,g' '{}' \\;");
            $instance->ssh_assert_script_run("sudo find /tmp/repos/ -name *.repo -exec zypper ar -p10 '{}' \\;");
            $instance->ssh_assert_script_run("sudo find /tmp/repos/ -name *.repo -exec echo '{}' \\;");

            $instance->ssh_assert_script_run("zypper lr -P");
        }
    }
}

sub test_flags {
    return {fatal => 1, publiccloud_multi_module => 1};
}

1;

