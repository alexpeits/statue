{ pkgs ? import <nixpkgs> {} }:

let

  defaults = {
    postsDir = "posts";
    staticDir = "static";
    extraFilesDir = "extra_files";
    otherPages = [];
    buildInfo = true;
  };

  checkConfig = config:
    assert config ? siteTitle;
    assert config ? useTags;
    config;

in

{
  mkConfig = config: defaults // config;
}
