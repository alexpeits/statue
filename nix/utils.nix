{ pkgs ? import <nixpkgs> {} }:

let

  lib = pkgs.lib;
  b = builtins;

  onlyOne = x:
    if b.typeOf x == "list"
    then lib.elemAt x 0
    else x;
in

rec {

  # from a filename that looks like this: "2020-10-11-whatever.md", return a
  # record of the date components
  extractDate = fname:
    let
      parts = lib.forEach (lib.take 3 (lib.splitString "-" fname)) lib.toInt;
    in
      {
        year = lib.elemAt parts 0;
        month = lib.elemAt parts 1;
        day = lib.elemAt parts 2;
      };

  # true if dt1 < dt2, otherwise false, comparing year, then month, then day
  cmpDates = dt1: dt2:
    let
      y1 = dt1.year; m1 = dt1.month; d1 = dt1.day;
      y2 = dt2.year; m2 = dt2.month; d2 = dt2.day;
    in
      if y1 == y2 then (if m1 == m2 then d1 < d2 else m1 < m2) else y1 < y2;

  sortMds = mds:
    let
      cmp = md1: md2: cmpDates md1.meta.date md2.meta.date;
    in
      lib.sort (x: y: ! (cmp x y)) mds;

  # format a date like this: October 11, 2020
  fmtDate = { year, month, day }:
    let
      months =
        [
          "January"
          "February"
          "March"
          "April"
          "May"
          "June"
          "July"
          "August"
          "September"
          "October"
          "November"
          "December"
        ];
      fmtMonth = lib.elemAt months (month - 1);
    in
      "${fmtMonth} ${b.toString day}, ${b.toString year}";

  # format a date like this: 2020.08.09 (month and day are padded with 0)
  fmtDateShort = { year, month, day }:
    let
      pad = x: lib.fixedWidthString 2 "0" (b.toString x);
    in
      "${b.toString year}.${pad month}.${pad day}";

  # preprocess meta values and add some defaults
  processMeta = fname: meta:
    meta // {
      title = onlyOne meta.title;
      description =
        if (meta ? description)
        then onlyOne meta.description
        else null;
      date = extractDate fname;
      tags = if (meta ? tags) then meta.tags else [];
    };

  # from a list of parsed markdown files, return a mapping from tag to list of
  # markdowns that have this tag
  tagsMap = mds:
    let
      go = acc: md: lib.foldl (addTag md) acc md.meta.tags;
      addTag = md: acc: t:
        let
          v = if (acc ? "${t}") then acc."${t}" else [];
        in
          acc // { "${t}" = v ++ [ md ]; };
      mapping = lib.foldl go {} mds;
    in
      lib.mapAttrs (k: v: sortMds v) mapping;

  # filepath helpers
  allFilesIn = path: b.attrNames (b.readDir path);
  allFilesWithExtsIn = path: exts:
    b.filter (n: b.match ''.*\.(${lib.concatStringsSep "|" exts})'' n != null) (allFilesIn path);
  allFilepathsWithExtsIn = path: exts:
    map (n: path + ("/" + n)) (allFilesWithExtsIn path exts);

  # split a path into the base name and the extension
  getParts = path:
    let
      parts = lib.splitString "." (lib.last (lib.splitString "/" (b.toString path)));
    in
      { fname = lib.head parts; ext = lib.last parts; };

  py = pkgs.python37.withPackages (p: [ p.markdown ]);
  parseFile = path:
    let
      ext = (getParts path).ext;
    in
      if ext == "md" then parseMd path else
        if ext == "nix" then parseNix path else
          abort "Unknown extension ${ext}";

  parseMd = path:
    let
      fname = (getParts path).fname;
      name = b.replaceStrings [ "/" "." ] [ "-" "-" ] fname;

      meta = pkgs.runCommand (name + "-meta") { buildInputs = [ pkgs.bash pkgs.yq ]; } ''
        bash -c '${../scripts/extract-yaml-metadata.sh} ${path}' | yq -j -r . > $out
      '';

      html = pkgs.runCommand (name + "-html") { buildInputs = [ pkgs.pandoc ]; } ''
        pandoc ${path} --mathjax --to=html > $out
      '';

    in
      {
        meta = processMeta fname (lib.importJSON meta);
        html = lib.readFile html;
        fname = fname;
      };

  parseNix = path:
    let
      fname = (getParts path).fname;
      name = b.replaceStrings [ "/" "." ] [ "-" "-" ] fname;
      file = import path { pkgs = pkgs; };
      html = pkgs.runCommand (name + "-html") { buildInputs = [ pkgs.pandoc ]; } ''
        pandoc --mathjax --to=html << \EOF > $out
          ${file.content}
        EOF
      '';
    in
      {
        meta = processMeta fname file.meta;
        html = lib.readFile html;
        fname = fname;
      };
}
