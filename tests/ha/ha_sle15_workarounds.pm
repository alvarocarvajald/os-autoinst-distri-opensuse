# SUSE's openQA tests
#
# Copyright 2017-2018 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: Add some SLE15 workarounds
#          Should be removed after SLE15 will be released!
# Maintainer: QE-SAP <qe-sap@suse.de>, Loic Devulder <ldevulder@suse.com>

use base 'opensusebasetest';
use strict;
use warnings;
use version_utils 'is_sle';
use testapi;
use hacluster;
use power_action_utils qw(power_action);
use bootloader_setup qw(add_grub_cmdline_settings);

# Do some stuff that need to be workaround in SLE15
sub run {
    my ($self) = @_;
    return unless is_sle('15+');

    # Modify the device number if needed
    if ((get_var('ISO', '') eq '') && (get_var('ISO_1', '') ne '')) {
        assert_script_run "sed -i 's;sr1;sr0;g' /etc/zypp/repos.d/*";
    }

    if (is_sle('16+')) {
        #return;
        assert_script_run q|sed -i -e '/^GRUB_CMDLINE_LINUX_DEFAULT/s/security=selinux//' -e '/^GRUB_CMDLINE_LINUX_DEFAULT/s/selinux=[01]//' -e '/^GRUB_CMDLINE_LINUX_DEFAULT/s/enforcing=[01]//' /etc/default/grub|;
        add_grub_cmdline_settings('security=apparmor', update_grub => 0);
        add_grub_cmdline_settings('selinux=0', update_grub => 1);
        add_grub_cmdline_settings('enforcing=0', update_grub => 0);
        assert_script_run 'grep GRUB_CMDLINE_LINUX_DEFAULT /etc/default/grub';
        power_action('reboot', keepconsole => 1, textmode => 1);
        $self->wait_boot(nologin => 0, bootloader_time => 300);
        reset_consoles;
        select_console 'root-console';
    }
}

1;
