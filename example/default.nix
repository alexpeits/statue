let
  config = {
    siteTitle = "Example site";
    navPages = [ ./about.md ];
    rootDir = ./.;
    postsDir = ./posts;
    buildInfo = false;
    htmlHead = ''
      <link rel="stylesheet" href="/css/default.css" />
      <link rel="stylesheet" href="/css/syntax.css" />
    '';
  };
in
# use fetchFromGitHub + import instead
import ../. { config = config; }
