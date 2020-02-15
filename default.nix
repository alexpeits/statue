{ pkgs ? import <nixpkgs> {}, templateOverrides ? {}, config }:

let

  lib = pkgs.lib;
  b = builtins;
  utils = import ./nix/utils.nix { pkgs = pkgs; };

  mkConfig = (import ./nix/config.nix { pkgs = pkgs; }).mkConfig;
  conf = mkConfig config;
  tmpl =
    import ./nix/templates.nix {
      pkgs = pkgs;
      config = conf;
    } // templateOverrides;

  postsDir = ./. + ("/" + conf.postsDir);
  staticDir = ./. + ("/" + conf.staticDir);
  extraFilesDir = ./. + ("/" + conf.extraFilesDir);

  navPages = map utils.parseMd conf.navPages;
  navPagesScript =
        let
      script = md: ''
        cat << \EOF > $out/${md.fname}.html
          ${baseTmpl md.meta.title md.html}
        EOF
      '';
    in
      b.concatStringsSep "\n" (map script navPages);

  baseTmpl = tmpl.base navPages;

  posts = map utils.parseMd (utils.allFilepathsWithExtIn postsDir "md");
  postsTable = baseTmpl "Posts" (tmpl.postsTable posts);
  postPagesScript =
    let
      script = md: ''
        cat << \EOF > $out/${tmpl.postUrl md}
          ${baseTmpl md.meta.title (tmpl.postPage md)}
        EOF
      '';
    in
      b.concatStringsSep "\n" (map script posts);

  tags = utils.tagsMap posts;
  mkTagPage = tag: mds:
    baseTmpl ''Posts tagged "${tag}"'' (tmpl.postsList mds);

  tagsList = baseTmpl "Tags" (tmpl.tagsList tags);
  tagPages = lib.mapAttrs mkTagPage tags;
  tagPagesScript =
    let
      script = tag: content: ''
        cat << \EOF > $out/${tmpl.tagUrl tag}
          ${content}
        EOF
      '';
    in
      b.concatStringsSep "\n" (lib.attrValues (lib.mapAttrs script tagPages));

  buildInfo = "build-info.txt";
  buildInfoScript = ''
    rm -f $out/${buildInfo}
    git -C ${./.} log -1 --format="%H%n%cd" > $out/${buildInfo}
  '';

in

pkgs.runCommand "site" { buildInputs = [ pkgs.git ]; } ''
  # static files
  mkdir -p $out/static
  cp -R ${staticDir}/* $out/static

  # index
  cat << \EOF > $out/index.html
    ${postsTable}
  EOF

  # posts
  mkdir -p $out/posts
  ${postPagesScript}

  # tags list
  cat << \EOF > $out/tags.html
    ${tagsList}
  EOF

  # per-tag pages
  mkdir -p $out/tags
  ${tagPagesScript}

  # nav pages
  ${navPagesScript}

  # extra files, copy as-is
  cp -R ${extraFilesDir}/* $out/

  ${if conf.buildInfo then buildInfoScript else ""}
''
