package Plugins::CommunityFirmware::Settings;

use strict;
use base qw(Slim::Web::Settings);

use Slim::Utils::Prefs;
use Slim::Utils::Log;

my $prefs = preferences('plugin.communityfirmware');
my $log = logger('player.firmware');

my %defaults = (
	enable	=> '1',
	beta	=> '0',
);

sub name {
	return 'PLUGIN_COMMUNITY_FIRMWARE';
}

sub page {
	return 'plugins/CommunityFirmware/settings.html';
}

sub prefs {
        my @prefs = ($prefs, qw(enable beta));

        return @prefs;
}

sub setDefaults {
	my $force = shift;

	foreach my $key (keys %defaults) {
		if (!defined($prefs->get($key)) || $force) {
			$log->info("Missing pref value: Setting default value for $key: " . $defaults{$key});
			$prefs->set($key, $defaults{$key});
		}
	}
}

sub init {
        $log->info("Initializing settings");
        setDefaults(0);
}

1;
