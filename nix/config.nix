{ pkgs ? import <nixpkgs> {} }:

let

  defaults = config: {
    navPages = [];
    copyFilesDir = config.rootDir + "/static";
    extraFilesDir = null;
    buildInfo = true;
    htmlHead = "";
  };

in

{
  mkConfig = config:
    assert config ? siteTitle;
    assert config ? rootDir;
    assert config ? postsDir;
    defaults config // config;
}
