package Plugins::CommunityFirmware::Settings;

use strict;
use base qw(Slim::Web::Settings);

use Slim::Utils::Prefs;

my $prefs = preferences('plugin.communityfirmware');

sub name {
	return 'PLUGIN_COMMUNITY_FIRMWARE';
}

sub page {
	return 'plugins/CommunityFirmware/settings.html';
}

sub prefs {
	my @prefs = qw(enable beta);
	return ($prefs, @prefs);
}


1;
