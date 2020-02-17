{ pkgs ? import <nixpkgs> {}, templateOverrides ? (x: x), config }:

let

  lib = pkgs.lib;
  b = builtins;
  utils = import ./nix/utils.nix { pkgs = pkgs; };

  mkConfig = (import ./nix/config.nix { pkgs = pkgs; }).mkConfig;
  conf = mkConfig config;
  oldTmpl = import ./nix/templates.nix { pkgs = pkgs; config = conf; };
  tmpl = oldTmpl // templateOverrides oldTmpl;

  postsDir = conf.postsDir;

  navPages = map utils.parseFile conf.navPages;
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

  posts = map utils.parseFile (utils.allFilepathsWithExtsIn postsDir [ "md" "nix" ]);
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
    git -C ${conf.rootDir} log -1 --format="%H%n%cd" > $out/${buildInfo}
  '';

  copyFilesScript =
    if conf.copyFilesDir != null
    then "cp -R ${conf.copyFilesDir}/* $out"
    else "";

in

pkgs.runCommand "site" { buildInputs = [ pkgs.git ]; } ''
  mkdir $out

  # copy files from copyFilesDir as-is
  ${copyFilesScript}

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

  ${if conf.buildInfo then buildInfoScript else ""}
''
