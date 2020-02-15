#!/usr/bin/env python
import argparse
import sys
import json

from feedgen.feed import FeedGenerator


def posts_type(raw_posts):
    posts = json.loads(raw_posts)
    assert isinstance(posts, list)
    for post in posts:
        assert isinstance(post, dict)
        assert "title" in post
        assert "link" in post
        assert "year" in post
        assert "month" in post
        assert "day" in post

    return posts


def populate_post(post, title, link, year, month, day):
    post.title(title)
    post.link(link)
    post.pubDate("{}-{}-{}T00:00:00Z".format(year, month, day))


def main(title, author_name, author_email, link, language, posts, format):
    feed = FeedGenerator()
    feed.title(title)
    feed.author({"name": author_name, "email": author_email})
    feed.link(href=link, rel="alternate")
    feed.language(language)
    for post_info in posts:
        post = feed.add_entry()
        populate_post(post, **post_info)
    if format == "rss":
        return feed.rss_str()
    elif format == "atom":
        return feed.atom_str()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate rss feeds from posts."
    )
    parser.add_argument(
        "--output",
        dest="output",
        default=sys.stdout,
        help="Output file (defaults to stdout)",
    )
    parser.add_argument("--title", dest="title", help="Feed title")
    parser.add_argument(
        "--author-name", dest="author_name", help="Feed author name"
    )
    parser.add_argument(
        "--author-email", dest="author_email", help="Feed author email"
    )
    parser.add_argument("--link", dest="link", help="Feed link")
    parser.add_argument(
        "--language", dest="language", default="en", help="Feed language"
    )
    parser.add_argument(
        "--posts",
        dest="posts",
        action="append",
        type=posts_type,
        help="One or more posts, formatted as JSON",
    )
    parser.add_argument(
        "--relative",
        dest="relative",
        action="store_true",
        default=False,
        help=(
            "If specified, the post links supplied are relative and will be "
            "appended to the `link` argument"
        ),
    )
    parser.add_argument(
        "--format",
        dest="format",
        choices=["rss", "atom"],
        default="rss",
        help="Feed format",
    )
    args = parser.parse_args()

    feed_output = main(
        title=args.title,
        author_name=args.author_name,
        author_email=args.author_email,
        link=args.link,
        language=args.language,
        posts=args.posts,
        format=args.format,
    )

    if type(args.output) == str:
        with open(args.output, "w") as f:
            f.write(feed_output)
    else:
        args.output.write(feed_output)
