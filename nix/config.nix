{ pkgs ? import <nixpkgs> {} }:

let

  defaults = {
    navPages = [];
    buildInfo = true;
    htmlHead = "";
  };

in

{
  mkConfig = config:
    assert config ? siteTitle;
    assert config ? rootDir;
    assert config ? postsDir;
    assert config ? staticDir;
    defaults // config;
}
