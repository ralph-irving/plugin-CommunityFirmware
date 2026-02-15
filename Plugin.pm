package Plugins::CommunityFirmware::Plugin;

use strict;

use base qw(Slim::Plugin::Base);
use File::Spec::Functions qw(catfile);

use Slim::Utils::Firmware;
use Slim::Utils::Prefs;

my $DEFAULT_REPOSITORY;

BEGIN {
	$DEFAULT_REPOSITORY = Slim::Utils::Firmware::BASE();
}

my $prefs = preferences('plugin.communityfirmware');

sub initPlugin {
	if (main::WEBUI) {
		require Plugins::CommunityFirmware::Settings;
		Plugins::CommunityFirmware::Settings->new();
	}

	$prefs->setChange(sub {
		my %seen;

		my $updatesDir = Slim::Utils::OSDetect::dirsFor('updates');

		for my $client ( Slim::Player::Client::clients() ) {
			next if $seen{$client->id}++;
			my $model = $client->model;

			if ( $prefs->get('enable') ) {
				Slim::Utils::Firmware::init_firmware_download($model);
			}
			else {
				Slim::Utils::Misc::deleteFiles($updatesDir, qr/^${model}_\d+\.\d+\.\d+_.*\.bin(\.tmp)?$/i);
				Slim::Utils::Misc::deleteFiles($updatesDir, qr/^$model\.version$/i);
			}
		}

	}, 'enable');

	preferences('server')->set('checkVersion', 1);
}

1;


package Slim::Utils::Firmware;

use strict;

use Slim::Utils::Log;

my $log = logger('player.firmware');

sub CHECK_INTERVAL {
	return Slim::Utils::Prefs::preferences('server')->get('checkVersionInterval');
}

sub BASE {
	my $hint = shift;

	my $COMMUNITY_FIRMWARE_REPOSITORY = ($prefs->get('beta') && (!$hint || $hint =~ /jive|fab4|baby/))
		? 'https://ralph_irving.gitlab.io/lms-community-firmware-beta/update/firmware/'
		: 'https://ralph_irving.gitlab.io/lms-community-firmware/update/firmware/';

	my $url = ($prefs->get('enable') && (!$hint || $hint =~ /jive|fab4|baby/))
		? $COMMUNITY_FIRMWARE_REPOSITORY
		: $DEFAULT_REPOSITORY;

	main::INFOLOG && $log->is_info && $log->info("Firmware check URL: $url");

	return $url;
}

1;
