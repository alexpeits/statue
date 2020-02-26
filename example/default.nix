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
    extraScript = {
      inputs = p: [ p.minify ];
      script = ''
        cp -R ${./static/whatever.txt} $out

        mkdir -p $out/css
        for css in $(find ${./static/css} -name '*.css'); do
          minify -o $out/css/$(basename $css) $css
        done
      '';
    };
  };
in
# use fetchFromGitHub + import instead
import ../. { config = config; }
