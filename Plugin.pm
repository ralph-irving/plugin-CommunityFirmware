package Plugins::CommunityFirmware::Plugin;

use strict;

use base qw(Slim::Plugin::Base);

use Slim::Networking::Repositories;
use Slim::Utils::Firmware;
use Slim::Utils::Prefs;

my $DEFAULT_REPOSITORY;

my $prefs = preferences('plugin.communityfirmware');

sub initPlugin {
	if (main::WEBUI) {
		require Plugins::CommunityFirmware::Settings;
		Plugins::CommunityFirmware::Settings->new();
	}

	$DEFAULT_REPOSITORY ||= Slim::Networking::Repositories->getUrlForRepository('firmware');

	preferences('server')->set('checkVersion', 1);
}

1;


package Slim::Utils::Firmware;

use strict;

use Slim::Utils::Log;

use constant COMMUNITY_FIRMWARE_REPOSITORY => 'https://ralph_irving.gitlab.io/lms-community-firmware/update/firmware/';

my $log = logger('player.firmware');

sub BASE {
	my $hint = shift;

	my $url = ($prefs->get('enable') && (!$hint || $hint =~ /jive|fab4|baby/))
		? COMMUNITY_FIRMWARE_REPOSITORY
		: $DEFAULT_REPOSITORY;

	main::INFOLOG && $log->is_info && $log->info("Firmware check URL: $url");

	return $url;
}

1;
