{ pkgs ? import <nixpkgs> {} }:

with pkgs.lib;

let

  b = pkgs.builtins;

in

{

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
      title = lib.elemAt meta.title 0;
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
  allFilepathsIn = path: map (n: path + ("/" + n)) (allFilesIn path);
  allFilesWithExtIn = path: ext:
    b.filter (n: b.match ".*\\.${ext}" n != null) (allFilesIn path);
  allFilepathsWithExtIn = path: ext:
    map (n: path + ("/" + n)) (allFilesWithExtIn path ext);

}
