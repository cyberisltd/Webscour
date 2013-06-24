Webscour
========

* Author: geoff.jones@cyberis.co.uk
* Copyright: Cyberis Limited 2013
* License: GPLv3 (See LICENSE)

Webscour is a Perl script (with gnome dependencies) to help identify interesting websites during a penetration test.

Provides a quick visual overview of web sites and response capture from a list of hostnames/ports fed via STDIN. Pipe straight from your favourite port scanner, grep for http[s] into webscour.pl, and you'll get a nicely formatted HTML page containing thumbnails and the response headers from each site.

```bash
echo -e "www.google.co.uk:80\nwww.yahoo.co.uk" | ./webscour.pl /tmp/out.htm
```

Dependencies
------------
* gnome-web-photo (or edit the script to use a thumbnailer of your choice)
* The following Perl modules:

```perl
use LWP::UserAgent;
use HTML::Entities;
use IO::Socket::SSL;
```

Issues
------
Kindly report all issues via https://github.com/cyberisltd/Webscour/issues
