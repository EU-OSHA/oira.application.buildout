vcl 4.0;

backend default {
    .host = "127.0.0.1";
    .port = "13280";
}

acl purge {
    "127.0.0.1";
    "localhost";

}
sub vcl_recv {
    if (req.method == "PURGE") {
        if (!client.ip ~purge) {
            return (synth(405, "Not allowed."));
        }
        return(purge);
    }

    # Only deal with "normal" types
    if (req.method != "GET" &&
        req.method != "HEAD" &&
        req.method != "PUT" &&
        req.method != "POST" &&
        req.method != "TRACE" &&
        req.method != "OPTIONS" &&
        req.method != "PATCH" &&
        req.method != "DELETE") {
      /* Non-RFC2616 or CONNECT which is weird. */
      return (pipe);
    }

    # Implementing websocket support (https://www.varnish-cache.org/docs/4.0/users-guide/vcl-example-websockets.html)
    if (req.http.Upgrade ~ "(?i)websocket") {
      return (pipe);
    }

    # Only cache GET or HEAD requests. This makes sure the POST requests are always passed.
    if (req.method != "GET" && req.method != "HEAD") {
      return (pass);
    }
    // Remove has_js and Google Analytics __* cookies.
    set req.http.Cookie = regsuball(req.http.Cookie, "(^|;\s*)(__(ut|at|gads)[a-z]+|_pk_id.2.ef1b|_pk_ses.2.ef1b|_hj[a-z]+|has_js|_ga|_ZopeId)=[^;]*", "");
    // Remove a ";" prefix, if present.
    set req.http.Cookie = regsub(req.http.Cookie, "^;\s*", "");

    if (req.url ~ "(user-menu.html|update-completion-percentage)") {
      return (pass);
    }


    if (req.http.Authorization || req.http.Cookie ~ "__ac") {
            /* All assests from the theme should be cached anonymously */
        if (req.url !~ "euphorie\.resources/oira/(help|script|style|favicon|i18n|depts\.html)" &&
            req.url !~ "euphorie\.resources/media/") {
            return (pass);
        } else {
          unset req.http.Authorization;
          unset req.http.Cookie;
          return (hash);
        }
    }
}

#sub vcl_hash {
#  # Called after vcl_recv to create a hash value for the request. This is used as a key
#  # to look up the object in Varnish.
#
#  hash_data(req.url);
#
#  if (req.http.host) {
#    hash_data(req.http.host);
#  } else {
#    hash_data(server.ip);
#  }
#
#  # hash cookies for requests that have them
#  if (req.http.Cookie) {
#    hash_data(req.http.Cookie);
#  }
#}

sub vcl_backend_response {

  if (bereq.url ~ "euphorie\.resources/oira/(script|style|favicon|i18n|depts\.html)") {
      set beresp.ttl = 1209600s;
      set beresp.http.cache-control = "max-age=1209600;s-maxage=1209600";
      set beresp.http.max-age = "1209600";
      set beresp.http.s-maxage = "1209600";
      unset beresp.http.set-cookie;
      return (deliver);
  }

  /* if we have big images, user can cache them in the local browser cache for a day */
  if (bereq.url ~ "(image_preview.jpg|image_preview|image_large|@@images/image|dvpdffiles/|image_listing|image_icon|image_tile|image_thumb|image_mini)$") {
    set beresp.http.cache-control = "max-age=84600;s-maxage=0";
    set beresp.http.max-age = "84600";
    set beresp.http.s-maxage = "0";
#    set beresp.http.expires = "84600";
    unset beresp.http.set-cookie;
    return (deliver);
  }

  /* Cache Font files, regardless of where they live */
  if (bereq.url ~ "\.(otf|ttf|woff|svg|ico|jpg|gif|png|css|js|kss)") {
      set beresp.ttl = 1209600s;
      set beresp.http.cache-control = "max-age=1209600;s-maxage=1209600";
      set beresp.http.max-age = "1209600";
      set beresp.http.s-maxage = "1209600";
#      set beresp.http.expires = "1209600";
      unset beresp.http.set-cookie;
      return (deliver);
  }


  if (beresp.status >= 400 || beresp.status == 302) {
     set beresp.ttl = 0s;
  }

  /* should be the last rule */
  /* don't cache anything that looks like the login form, nor anything that has the __ac cookie */
  if ( bereq.url ~ "/login_form$" || bereq.http.Cookie ~ "__ac" ) {
     set beresp.uncacheable = true;
     set beresp.ttl = 120s;
     return (deliver);
  }

  return (deliver);
}

sub vcl_deliver {
  if (obj.hits > 0) { # Add debug header to see if it's a HIT/MISS and the number of hits, disable when not needed
    set resp.http.X-Cache = "HIT";
  } else {
    set resp.http.X-Cache = "MISS";
  }
  set resp.http.X-Hits = obj.hits;
  set resp.http.X-Cookie-Debug = "Request cookie: " + req.http.Cookie;

  if (req.url !~ "euphorie\.resources/oira/(script|style|favicon|i18n|depts\.html)") {
      set resp.http.X-Resource-Debug = "NO: Not in resource url";
  } else {
      set resp.http.X-Resource-Debug = "YES: In resource url";
  }
  # Remove some headers: Apache version & OS
  unset resp.http.Server;
  unset resp.http.X-Drupal-Cache;
  unset resp.http.X-Varnish;
  unset resp.http.Via;
  unset resp.http.Link;
  unset resp.http.X-Generator;
}

# vim: set sw=4 et:
