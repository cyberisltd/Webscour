#!/usr/bin/perl

#    Usage: cat filecontainingwebsites | ./webscour.pl output.htm

#    Written by Geoff Jones geoff.jones@cyberis.co.uk
#    v0.1 - 16/04/2011
#    v0.2 - 18/07/2012 bug fixes, addition of sig alarm for timeout situations

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use LWP::UserAgent;
use HTML::Entities;
use IO::Socket::SSL;

my $GNOMEWEBPHOTO = "/usr/bin/gnome-web-photo";
# Timeout for forked processes (like gnome-web-photo)
my $forktimeout = 25;

# Connection timeout
my $timeout = 5;

if (@ARGV != 1) {
	usage();
	exit 1;
}
elsif (-e $ARGV[0]) {
	print STDERR "\tError: output file exists. Please remove or select a different name.\n";
	usage();
	exit 2;
}

open FILE, ">", "$ARGV[0]" or die $!;
my $dir = "$ARGV[0]_files";
mkdir($dir) or die $!;

print FILE <<HEADER;
<html>
<head>
 <STYLE type="text/css">
   body, h1, h2 {
	font-size: 10pt; 
	font-family: Verdana, Tahoma, Helvetica, Arial;
   }
 </STYLE>
</head>
<body>
<table>
HEADER

my $browser = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
$browser->timeout($timeout);

my $line = 0;

while(<STDIN>) {
	chomp;
   	my $url = $_;

	my $response;	

	eval {
		local $SIG{ALRM} = sub { die "[ERROR] Download took too long\n" };
		alarm $timeout + 2;
		#Check to see whether the host/port combo is running https
		if (IO::Socket::SSL->new(PeerAddr=>"$url",timeout=>$timeout)) {
			#site is https
			if ($url !~ m#^https://#i) {
				$url =~ s#^#https://#;
   			}
		} elsif ($url !~ m#^http://#i) {
			$url =~ s#^#http://#;
		}
		alarm 0;
	};

     	if ($@) {
                print STDERR "[ERROR] Timeout during SSL Connection. Trying HTTP instead.\n";
		if ($url !~ m#^http://#i) {
                        $url =~ s#^#http://#;
                }
        }

	eval {
		local $SIG{ALRM} = sub { die "[ERROR] Download took too long.\n" };
                alarm $timeout;

		print "Getting $url\n";

		$response = $browser->get($url);
		alarm 0;
	};

	if ($@) {
		print STDERR "[ERROR] Timeout during LWP request. Skipping host.\n";
		print FILE "<tr><td></td><td><h1>Failed to get $url -- timeout </h1>\n</td></tr>";
                next;
	}

 	if (! $response->is_success) {
		print FILE "<tr><td></td><td><h1>Failed to get $url -- ", 
		encode_entities($response->status_line), "</h1>";
		print FILE "<h2>RESPONSE HEADERS:</h2>\n<pre>" . encode_entities($response->headers_as_string) . 
			"\n</pre></td></tr>";
		next;
	}

	my $html = $response->content;
	print FILE "<tr><td>";

	# Take the screenshot
	my $pid = fork;
	if ($pid > 0){
    		eval{
        		local $SIG{ALRM} = sub {kill 9, -$pid; die "[ERROR] Timeout during screenshot."};
	        	alarm $forktimeout;
        		waitpid($pid, 0);
        		alarm 0;
    		};
	}
	elsif ($pid == 0){
    		setpgrp(0,0);
    		exec("$GNOMEWEBPHOTO --force --mode=thumbnail \"$url\" \"$dir/$line.png\" 2> /dev/null");
	}

	if ($@) {
		print STDERR "[ERROR] Timeout during screenshot capture.\n";
		print FILE "</td><td>";
	}
	else {
		print FILE "<a href='$url' target='_blank'><img src='$dir/$line.png'/></a></td><td>";
	}
	
	print FILE "<h1>SITE: <a href='$url' target='_blank'>" . encode_entities($url) . "</a></h1>\n";
	if ($html =~ m#<title.*?>([^<]*)</title#i) {
		print FILE "<h2>TITLE: " . encode_entities($1) . "</h2>\n";
	}
	elsif ($html =~ m#<h.*?>([^<]*)</h#i) {
		print FILE "<h2>FIRST HEADER (no title found): ". encode_entities($1) . "</h2>\n";
	}

	print FILE "<h2>RESPONSE HEADERS:</h2>\n<pre>" 
		. encode_entities($response->headers_as_string) . 
		"\n</pre></td></tr>";
	$line ++;
}

print FILE <<FOOTER;
</table>
</body>
</html>
FOOTER
	
close(FILE);

sub usage {
	print "\n\tUsage: echo -n 'www.google.co.uk:80\\nwww.yahoo.com:80' | $0 output.htm\n\n"
}
