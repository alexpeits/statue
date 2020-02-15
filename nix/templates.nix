{ pkgs ? import <nixpkgs> {}, config }:

let

  lib = pkgs.lib;
  b = builtins;
  utils = import ./utils.nix {};
  mkNavPage = md:
    ''<a class="nav-link" href="/${md.fname}.html">${md.meta.title}</a>'';

in

rec {
  postUrl = { fname, ... }: "/posts/${fname}.html";
  tagUrl = tag: "/tags/${tag}.html";

  base = navPages: title: content: ''
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta http-equiv="x-ua-compatible" content="ie=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>${config.siteTitle} - ${title}</title>
        ${config.htmlHead}
      </head>
      <body>
        <header>
          <div class="logo">
            <a href="/">${config.siteTitle}</a>
          </div>
          <nav>
            <a class="nav-link" href="/">Home</a>
            <a class="nav-link" href="/tags.html">Tags</a>
            ${lib.concatStringsSep "\n" (map mkNavPage navPages)}
          </nav>
        </header>

        <main role="main">
          <h1>${title}</h1>
          ${content}
        </main>

        <footer>
          Site generated using nix + <a href="https://github.com/alexpeits/statue.git">statue</a>
        </footer>
      </body>
    </html>
  '';

  postPage = { meta, html, ... }: ''
    <article>
      <section class="header">
        Posted on ${utils.fmtDate meta.date}
      </section>
      <section class="header tags">
        ${if (b.length meta.tags == 0) then "" else "Tags:"} ${b.concatStringsSep ", " (map tagLink meta.tags)}
      </section>
      <section>
        ${html}
      </section>
    </article>
  '';

  postSummaryTable = md: ''
    <tr>
      <td class="posts-table-date">${utils.fmtDateShort md.meta.date}</td>
      <td>
        <a href="${postUrl md}" class="posts-table-title">${md.meta.title}</a>
        <div class="posts-table-tags tags">
          ${b.concatStringsSep ", " (map tagLink md.meta.tags)}
        </div>
      </td>
    </tr>
  '';

  postsTable = mds: ''
    <table class="posts-table">
      <tbody>
        ${b.concatStringsSep "\n" (map postSummaryTable (utils.sortMds mds))}
      </tbody>
    </table>
  '';

  postSummaryList = md: ''
    <li>
      <a href="${postUrl md}">${md.meta.title}</a> - ${utils.fmtDate md.meta.date}
    </li>
  '';

  postsList = mds: ''
    <ul>
      ${b.concatStringsSep "\n" (map postSummaryList mds)}
    </ul>
  '';

  tagLink = tag: "<a href=\"/tags/${tag}.html\">${tag}</a>";

  tagSummaryList = tag: mds: ''
    <li class="tags">
      <a href="${tagUrl tag}">${tag}</a>
    </li>
  '';

  tagsList = tags: ''
    <ul>
      ${b.concatStringsSep "\n" (lib.attrValues (lib.mapAttrs tagSummaryList tags))}
    </ul>
  '';
}
