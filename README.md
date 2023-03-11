# everyBASIC.info

This is kind of a "public backup repository" for the **https://everybasic.info** website.

I plan to keep it updated regularly, _from_ the wiki. At the moment, this means that I can not accept pull requests from here: the website is a wiki and its contents should be updated _there_.

## What's inside

As of its launch in 2023-03-11, the everyBASIC website was based on [DokuWiki](https://dokuwiki.org), with the following plugins:

- [catlist](http://www.dokuwiki.org/plugin:catlist)
- [Comment Syntax Support](https://www.dokuwiki.org/plugin:commentsyntax)
- [imagebox](https://www.dokuwiki.org/plugin:imagebox)
- [nspages](http://www.dokuwiki.org/plugin:nspages)
- [pagelist](http://www.dokuwiki.org/plugin:nspages)
- [simplenavi)(http://www.dokuwiki.org/plugin:simplenavi)
- [Tag](http://www.dokuwiki.org/plugin:tag)
- [Wrap](http://www.dokuwiki.org/plugin:wrap)


The 'data' directory contains a _partial_ copy of the website's DokuWiki _/data_ directory. More specifically, the directories where the pages, media files and their metadata are stored. They should work when copied to a DokuWiki installation, but will certainly require the DokuWiki index to be rebuilt. An easy tool for that is the _SearchIndex_ plugin (https://www.dokuwiki.org/plugin:searchindex).

### kwPageGen

The 'kwPageGen' directory contains a dirty tool I wrote for mass generating and updating pages of the Keywords section from a table in Google Sheets I have been using to catalog keywords from each different BASIC implementation I find.

It is a Tcl/Tk script, so it requires the _tclsh_ interpreter installed in the system (sorry: my BASIC knowledge is still way too rusty for writing something like that, but I'd like to try soon). Tcl is a great small language. Some people can write powerful and elegant programs with it. Some other people can use it to write lame code. I do.

Other than a CSV copy of the table, the script uses a directory containing at least a copy of a DokuWiki page template file. If this directory already contains page files for keywords listed in the CSV file, these files will only have their **Implemented By** and **With varaitions** sections replaced. Any other content is (or _should be_) preserved. This directory, the template file path, the CSV field separator character and some properties of the CSV table are configured in the script itself, in constants defined by its first lines.