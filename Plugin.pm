package Plugins::CommunityFirmware::Plugin;

use strict;

use base qw(Slim::Plugin::Base);
use File::Spec::Functions qw(catfile);

use Slim::Utils::Firmware;
use Slim::Utils::Prefs;
use Slim::Utils::Log;

my $log = logger('player.firmware');

my $DEFAULT_REPOSITORY;

BEGIN {
	$DEFAULT_REPOSITORY = Slim::Utils::Firmware::BASE();
}

my $prefs = preferences('plugin.communityfirmware');

$prefs->init({
	enable => 1,
	beta   => 0,
});

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

				main::INFOLOG && $log->is_info && $log->info("Removing downloaded firmware from $updatesDir");
			}
		}
	}, 'enable');

	# make sure the falsy value is never undefined, or it would get re-initialised with defaults
	$prefs->setChange(sub {
		my ($pref, $val) = @_;
		$prefs->set($pref, $val || 0);
	}, 'enable', 'beta');

	preferences('server')->set('checkVersion', 1);
}

1;


package Slim::Utils::Firmware;

use strict;

use constant COMMUNITY_FIRMWARE_REPOSITORY => 'https://ralph_irving.gitlab.io/lms-community-firmware/update/firmware/';
use constant COMMUNITY_BETA_FIRMWARE_REPOSITORY => 'https://ralph_irving.gitlab.io/lms-community-firmware-beta/update/firmware/';

sub CHECK_INTERVAL {
	return Slim::Utils::Prefs::preferences('server')->get('checkVersionInterval');
}

sub BASE {
	my $hint = shift;

	my $url = ($prefs->get('enable') && (!$hint || $hint =~ /jive|fab4|baby/))
		? ($prefs->get('beta') ? COMMUNITY_BETA_FIRMWARE_REPOSITORY : COMMUNITY_FIRMWARE_REPOSITORY)
		: $DEFAULT_REPOSITORY;

	main::INFOLOG && $log->is_info && $log->info("Firmware check URL: $url");

	return $url;
}

1;
