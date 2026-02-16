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

sub handler {
	my ($class, $client, $params) = @_;

	$log->debug("CommunityFirmware->handler() called.");
	if ($params->{saveSettings}) {
                # make sure value is not undefined, or it gets re-initialized
		$prefs->set('enable', $params->{'pref_enable'} ||= '0');
		$prefs->set('beta', $params->{'pref_beta'} ||= '0');

		$log->debug("CommunityFirmware->saveSettings() enabled " . $prefs->get('enable') . " beta " . $prefs->get('beta'));
	}

	return $class->SUPER::handler( $client, $params );
}

sub setDefaults {
	my $force = shift;

	foreach my $key (keys %defaults) {
		if (!defined($prefs->get($key)) || $force) {
			$log->debug("Preference not found setting default value for $key " . $defaults{$key});
			$prefs->set($key, $defaults{$key});
		}
	}
}

sub init {
        $log->info("CommunityFirmware->init() Initializing settings");
        setDefaults(0);
}

1;
