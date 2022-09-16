# SUSE's openQA tests
#
# Copyright 2019-2021 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Package: cloud-regionsrv-client
# Summary: Register addons in the remote system
#   Registration is in registercloudguest test module
#
# Maintainer: <qa-c@suse.de>

use Mojo::Base 'publiccloud::basetest';
use version_utils;
use registration;
use warnings;
use testapi;
use strict;
use utils;
use publiccloud::utils;
use publiccloud::ssh_interactive "select_host_console";

sub run {
    my ($self, $args) = @_;

    # Preserve args for post_fail_hook
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

    foreach my $instance (@instances) {
        $self->{instance} = $instance;

        select_host_console();    # select console on the host, not the PC instance

        registercloudguest($instance);
        register_addons_in_pc($instance);
    }
}

sub post_fail_hook {
    my ($self) = @_;
    $self->{instance}->upload_log('/var/log/cloudregister', log_name => $autotest::current_test->{name} . '-cloudregister.log');
    if (is_azure()) {
        record_info('azuremetadata', $self->{instance}->run_ssh_command(cmd => "sudo /usr/bin/azuremetadata --api latest --subscriptionId --billingTag --attestedData --signature --xml"));
    }
    $self->SUPER::post_fail_hook;
}

sub test_flags {
    return {fatal => 1, publiccloud_multi_module => 1};
}

1;
