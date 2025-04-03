package Plugins::CommunityFirmware::DefaultTimezoneRequest;

# Implements a Request that provides a SqueezeOS based player with a default,
# Olson formatted, TimeZone string. The player will make the request whenever
# its own TimeZone has not been initialized. This typically follows a factory
# reset, or during first set up.

use strict;

use Slim::Utils::Log;
use Slim::Networking::SimpleAsyncHTTP;
use JSON::XS::VersionOneAndTwo;

# The server/url that provides us with a default Olson formatted TimeZone.
# The response is JSON formatted.
use constant TZGUESS_URL => 'https://stats.lms-community.org/api/time';

# The id of the request and the name of the returned value.
use constant REQUESTID   => 'getlmstimezone';
use constant RESULTNAME  => 'timezone';

my $log = logger('plugin.communityfirmware');


# 'init' is called by 'Plugins::CommunityFirmware::Plugin::InitPlugin'.
sub init {
	# Flags: 0 - no client required, 1 - is a query, 0 - no tags
	Slim::Control::Request::addDispatch([REQUESTID], [0, 1, 0, \&getTimezone]);
}

sub getTimezone {
	my $request = shift;

	# check that this is the correct query.
	if ($request->isNotQuery([[REQUESTID]])) {
		$log->error('Malformed query');
		$request->setStatusBadDispatch();
		return;
	}
	# this is an async request - we need this
	$request->setStatusProcessing();

	Slim::Networking::SimpleAsyncHTTP->new(
		\&getTZcb,
		\&getTZerr,
		{
			timeout => 10,
			request => $request,
		}
	)->get(TZGUESS_URL);
}


# Returns the retrieved TimeZone to SqueezeOS.

# Note that SqueezeOS:
#  (a) expects to receive a string,
#  (b) interprets the empty string as failure, and
#  (c) checks that it recognizes the TimeZone provided before acting on it.

sub getTZcb {
	my $http = shift;
	my $request = $http->params('request');

	# Server response should look like:
	# {"datetime":"2025-04-03T11:39:10.351+01:00","timezone":"Europe/London","offset":"GMT+1","offsetHours":1,"offsetMinutes":60,"isInDST":true}

	my $res = eval { from_json($http->content) };
	if ($@ || ref $res ne 'HASH') {
		$log->error($@ || 'Invalid JSON response: ' . $http->content);
		$res = {}; # guarantee that $res will be a hash ref
	}

	my $tz = $res->{'timezone'};
	if (!defined $tz || ref $tz) {
		$log->error('Unexpected JSON response, expected a timezone string: ' . $http->content);
		$tz = ''; # guarantee that $tz will be a string scalar
	}

	$tz = "$tz"; # ensure $tz is a string scalar
	# Trim any leading/trailing white space, should it be there.
	$tz =~ s/\A\s+|\s+\z//g;

	$log->info("TimeZone query: Retrieved TimeZone \"$tz\"");
	my $savedTz = $tz;

	# Sanity check on TimeZone string.

	# A TimeZone identifier is, essentially, a POSIX path with some
	# additional (more and less voluntary) restrictions. These are
	# indicated in the "theory" section of the tz distribution:
	#   https://github.com/eggert/tz/blob/main/theory.html

	# Path components should contain only A-Z, a-z, '.', '-', and '_'.
	# And we need '/' (directory) to join the path components together.
	# Note:
	#  Some "legacy" and "etc" TimeZones may also contain 0-9 and '+', but
	#  we do not expect or support such oddities.

	$tz = '' if $tz =~ m{[^A-Za-z._\-/]} ; # reject if any characters outside that range

	# Additional restrictions
	$tz = '' if $tz =~ m{^/}; # leading '/' not allowed
	$tz = '' if $tz =~ m{/$}; # trailing '/' not allowed
	$tz = '' if $tz =~ m{//}; # no path component to be empty
	$tz = '' if $tz =~ m{ ^- | /- }x; # no path component to start with a hyphen

	# Path components that consist of singleton '.' or doubleton '..' are
	# not allowed for obvious reasons.
	# Other than that, the "theory" section of the tz distribution does
	# allow "dots" elsewhere in TimeZone identifiers, but discourages
	# them. That said, there are none defined at present, and almost
	# certainly won't be. So just exclude any TimeZone containing a dot.
	$tz = '' if $tz =~ m{\.}; # no path component to contain a '.'

	$tz = '' if $tz eq 'Factory'; # special
	$tz = '' if $tz eq 'Etc/Unknown'; # special

	# Note:
	#  We do not guarantee to purge all invalid TimeZones with the above
	#  sanity checks, but SqueezeOS will not act on a TimeZone that it
	#  doesn't recognize.

	if ($tz ne $savedTz) {
		$log->warn("TimeZone query: Retrieved TimeZone \"$savedTz\" did not pass validation checks. Returning TimeZone \"$tz\" instead.");
	}

	# All done, return result to SqueezeOS.
	$request->addResult(RESULTNAME, $tz);
	$request->setStatusDone();
}


# Returns an empty TimeZone string to SqueezeOS. SqueezeOS will interpret this
# as failure.

sub getTZerr {
	my $http = shift;
	my $request = $http->params('request');

	$log->error("Failed to get TimeZone from ", join("\n", $http->url, $http->error));

	# Return an empty string to SqueezeOS.
	$request->addResult(RESULTNAME, '');
	$request->setStatusDone();
}

1;
