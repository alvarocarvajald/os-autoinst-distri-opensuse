# SUSE's openQA tests
#
# Copyright SUSE LLC
# SPDX-License-Identifier: FSFAP
# Maintainer: QE-SAP <qe-sap@suse.de>

use strict;
use warnings;
use Mojo::Base 'publiccloud::basetest';
use testapi;

sub test_flags {
    return {
        fatal => 1,
        milestone => 0,
        publiccloud_multi_module => 1
    };
}

sub run {
    my ($self, $run_args) = @_;
    $self->select_serial_terminal;
    my $provider = $self->{provider} = $run_args->{my_provider};
    my $instances = $run_args->{instances};
    my $out;

    foreach my $instance (@$instances) {
        record_info 'Instance', $instance->public_ip;
        $instance->wait_for_ssh();
        $out = $instance->run_ssh_command("sudo rpm -qa | grep kernel");
        record_info 'DTB', $out;
    }
}

1;
