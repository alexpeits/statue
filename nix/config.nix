{ pkgs ? import <nixpkgs> {} }:

let

  defaults = {
    postsDir = "posts";
    staticDir = "static";
    extraFilesDir = "extra_files";
    navPages = [];
    buildInfo = true;
  };

in

{
  mkConfig = config:
    assert config ? siteTitle;
    defaults // config;
}
