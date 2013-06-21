Webscour
========

Webscour is a Perl script (with gnome dependencies) to help identify interesting websites during a penetration test.

Author: geoff.jones@cyberis.co.uk
Copyright Cyberis Limited 2013


Provides a quick visual overview of web sites and response capture from a list of hostnames/ports fed via STDIN. Pipe straight from your favourite port scanner, grep for http[s] into webscour.pl, and you'll get a nicely formatted HTML page containing thumbnails and the response headers from each site.

e.g. echo -e "www.google.co.uk:80\nwww.yahoo.co.uk" | ./webscour.pl /tmp/out.htm

Currently the only dependency other than a few common Perl modules is gnome-web-photo, but you could replace this with your favourite thumbnailer to get the same effect.
