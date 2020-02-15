let
  config = {
    siteTitle = "Example site";
    navPages = [ ./about.md ];
    postsDir = ./posts;
    staticDir = ./static;
    htmlHead = ''
      <link rel="stylesheet" href="/static/css/default.css" />
      <link rel="stylesheet" href="/static/css/syntax.css" />
    '';
  };
in
# use fetchFromGitHub + import instead
import ../. { config = config; }
