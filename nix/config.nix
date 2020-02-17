{ pkgs ? import <nixpkgs> {} }:

let

  defaults = config: {
    navPages = [];
    rootDir = null;
    copyFilesDir = null;
    buildInfo = true;
    htmlHead = "";
  };

in

{
  mkConfig = config:
    assert config ? siteTitle;
    assert config ? postsDir;
    let
      conf = defaults config // config;
    in
      if (conf ? buildInfo && conf ? rootDir == null)
      then abort "rootDir is required if buildInfo is true"
      else conf;
}
