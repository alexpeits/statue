# statue

`statue` is a very simple and opinionated static site generator, written using
only nix. To generate the html content, it uses pandoc and a small python script
to extract the metadata from markdown files.

## Requirements

The only requirement is `nix`, so quit what you're doing and
[go install it](https://nixos.org/nix/download.html).

## Installation

No download is needed in order to use `statue`, since the nix expression can be
imported directly from this git repo:

```nix
statue = pkgs.fetchFromGitHub {
  owner = "alexpeits";
  repo = "statue";
  rev = "<commit sha>";
  sha256 = "<use nix-prefetch-git to get this>";
};
```

To get the `sha256` for a specific revision, do:

```bash
$ nix-prefetch-git https://github.com/alexpeits/statue <commit sha>
```

To call the expression, you need to specify some options in the configuration.

## Configuration

These are all the options that are configurable:

* `siteTitle` (required) - the site title that's used in the html `title` tag
* `rootDir` (required) - the root directory for the site
* `postsDir` (required) - the directory that contains posts
* `navPages` (default `[]`) - a list of paths to markdown/nix files that form
  the navbar
* `copyFilesDir` (default `rootDir + "/static"`) - a directory whose contents
  will be copied as-is to the output folder
* `buildInfo` (default `true`) - whether to create a `build-info.txt` file at
  the site root, containing the commit hash an time
* `htmlHead` (default `""`) - string that will be added to the html `head` tag,
  useful for adding css, scripts and favicons

## Usage

A very basic derivation (see also [the example](example/default.nix)), should
look like this:

```nix
let
  config = {
    siteTitle = "Example";
    navPages = [ ./about.md ];
    rootDir = ./.;
    postsDir = ./posts;
    buildInfo = false;
    htmlHead = ''
      <link rel="stylesheet" href="/css/default.css" />
      <link rel="stylesheet" href="/css/syntax.css" />
    '';
  };

  statue = pkgs.fetchFromGitHub {
    owner = "alexpeits";
    repo = "statue";
    rev = "<commit sha>";
    sha256 = "<use nix-prefetch-git to get this>";
  };
in
import statue { config = config; }
```

This will output the site to the `result` symlink directory, you can then copy
the contents to the desired target. For a full example, take a look at
[my site](https://github.com/alexpeits/alexpeits.github.io).

## Post format

Posts and nav pages can either be markdown files, or nix files.

### Markdown posts

Markdown posts need to include some meta-data in the form of front-matter, which
looks like this:

```markdown
---
title: Some post
tags: one
      two
---

content
```

the only required key is `title`, and `tags` can be multiple items, separated
by newlines as in the example above.

### Nix posts

Posts in nix can be useful to automate some repetition, e.g.
[listing your projects](https://github.com/alexpeits/alexpeits.github.io/blob/develop/projects.nix).
Nix posts are functions that expect `nixpkgs` as input, and should return a
record that looks like this:

```nix
{ meta = {
    title = "Some post";
    tags = [ "one" "two" ];
  };
  content = ''
    # Something
    content
  '';
}
```

where `content` is some markdown that is then converted to `html`.
