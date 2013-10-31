# Helpy Search

Helpy Search is a small Windows utility to enable rapid term search in multiple websites. Simply put, it opens multiple browser tabs after you select some text and press a hotkey. It is fully customizable.

## Usage

1. Make sure Helpy is running; it must be active to capture your input.
2. Select some text in any application.
3. Press `CTRL + Spacebar`. Your text will be inserted into urls you specify and opened in your default browser.

## Configuration

The `Helpy Config.txt` file configures the program's behavior with a simple language. You can open this file with notepad.

### Configuration Overview

Helpy Search will interpret this file each time you press its activation hotkeys. It consists primarily of urls to be opened, optionally with regex matching and custom hotkeys.

### Simplest Example

```
http://www.google.com/search?q=|e|
```

This example will simply open a google search for your selection. The pipes with an e (`|e|`) are where our text selection will be inserted. This is mildly useful, but we can do more.

### Multi-Search Example

```
http://www.google.com/search?q=|e|
http://en.wikipedia.org/w/index.php?search=|e|
http://www.youtube.com/results?search_query=|e|
```

This example will open 3 separate tabs simultaneously showing search results for your selection. This can already be quite sufficient for many. You may add as many urls as you like, but remember to add `|e|` where the site would expect your search terms.

### Custom Hotkey Example

```
http://www.google.com/search?q=|e|
http://en.wikipedia.org/w/index.php?search=|e|
http://www.youtube.com/results?search_query=|e|

!HOTKEY ^!space
https://twitter.com/search?q=|e|

!HOTKEY ^enter
https://plus.google.com/s/|e|
```

This is the same as the previous example, but it adds 2 custom hotkeys `CTRL + ALT + Spacebar` (`^!space`), which opens twitter with our search, and `CTRL + Enter` (`^enter`) which opens Google Plus. `!HOTKEY` will change the hotkey used for all urls that appear after it. You can create more hotkeys to open different urls. The hotkeys you may use are the same that AutoHotkey allows: read more [here](http://www.autohotkey.com/docs/Hotkeys.htm) (you won't need the 2 colons (`::`) in their examples.)

### Regex Example

```
!REGEX ^(https?://|www\.)[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,3}(/\S*)?$
||

!REGEX
http://www.google.com/search?q=|e|
http://en.wikipedia.org/w/index.php?search=|e|
http://www.youtube.com/results?search_query=|e|
```

This example detects if our selection was a url. If it was, it opens it in your browser -- if it wasn't, it searches Google, Wikipedia, and Youtube for your selection.

[Regex](http://en.wikipedia.org/wiki/Regular_expression) is a way to describe search patterns for text. For instance, we can use it to identify if your selected text is an internet url. The `!REGEX` command marks the start of a regex section, where all urls that appear after it are opened if the regex was a match. In the above example, there is a `!REGEX` command that will match urls, followed by empty pipes `||` which open the url directly in your browser. Then we see a blank `!REGEX` with no regex to its right, which acts like a "catch everything" bucket. This is where we can put our searches from before. Always remember: put the more specific regexes at the beginning; putting the url regex after the "catch all" blank regex will cause the url regex to never trigger.

### Flags

Inside of pipes (`||`) you may use:

- `e` - Encode text; this makes your text "safe" for insertion into urls. Also known as [Percent Encoding](http://en.wikipedia.org/wiki/Percent-encoding).
- `e-p` - Encode text and turn spaces into plusses (`+`) instead of `%20`. Mostly useless, only serves to make urls slightly prettier.
- `q` - Add quotes (`" "`) around your text. Useful for "exact matching" of search text.

If you are unsure which to use, you probably want `|e|`.

### Extra Features

- Any spaces or tabs before or after your urls will be ignored, so feel free to use tabs to organize everything as you see fit.
- Likewise, any whitespace (spaces/tabs/newlines) before or after any text you select will be stripped away, so you can be a bit sloppy when selecting text.
- You may enable or disable large sections of the config file with `!ON` and `!OFF`.
- Technically, Helpy can open anything windows would know how to run, not just urls. For example, if you give Helpy a file path it will open that file in its default program.

### Larger Example

```
!ON ==== SPECIAL CASES ====
!HOTKEY ^!s
  
  ; open urls (taken from: http://gist.github.com/823381)
  !REGEX ^(https?://|www\.)[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,3}(/\S*)?$
  ||
    
  ; open partial urls (e.g. gmail.com or it.wikipedia.org)
  !REGEX ^[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,3}(/\S*)?$
  http://||
  
  ; open windows files
  !REGEX .*\\([^\\]+$)
  ||

!ON ==== ALL OTHER CASES ====
!HOTKEY ^space

  !OFF ==== GENERAL SEARCH ====
    
    http://www.google.com/search?q=|e-pq|
    http://en.wikipedia.org/w/index.php?search=|e-pq|
    ; italian google search
    http://www.google.it/#hl=en&lr=lang_it&q=|e-pq|

  !ON ==== IT-EN SEARCH ====

    http://mymemory.translated.net/s.php?q=|e-p|&sl=it-IT&tl=en-GB
    http://www.proz.com/search/?term=|e-p|&from=ita&to=eng&es=1
    http://www.wordreference.com/iten/|e-p|
    http://translate.google.com/#it/en/|e-p|
```

### Comprehensive Syntax Listing

These commands must be used once per line at its beginning.

- `!ON` - Enables everything after it, until an `!OFF` is encountered. May have any text to its right as a comment if you wish.
- `!OFF` - Disables everything after it, until an `!ON` is encountered. May have any text to its right as a comment if you wish.
- `!HOTKEY` - Activates all urls after it when the hotkey is pressed. The `!HOTKEY` section ends when another `!HOTKEY` is found in the config file. Write the hotkey to its right.
- `!REGEX` - Activates all urls after it if the regex is a match. The `!REGEX` section ends when another `!REGEX` or `!HOTKEY` is found in the config file. Write the regex to its right.
- `;` - Disables this line. Write anything you wish to its right.

These may appear anywhere within a url.

- `||` - Option pipes. Insert option flags to modify your selected text.
- Flags - See: [Flags](#flags), must be inside of option pipes.

## How to Adapt to Your Needs

1. To use Helpy with a site of your choice, perform a search for anything you like.
2. Copy and paste the url of the search results page into `Helpy Config.txt`.
3. Identify the part where your search term is, and replace it with `|e|`.

## Troubleshooting

- If Helpy seems to stop responding (as it may do rarely), simply exit and start it again.
- Check that the hotkey you are pressing is actually registered with Helpy by clicking "Show active hotkeys" in the tray menu.
- You may have written your config incorrectly. Check that you haven't, for instance, put a more specific regex after a generic one.
- If your config is large and messy, try using "Show config data" from the tray menu. This shows you the simplified version of the config that is actually loaded in memory. It strips out any comments and `!OFF` sections.

## Sample Regexes

```
; open urls (from: http://gist.github.com/823381)
!REGEX ^(https?://|www\.)[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,3}(/\S*)?$
||
  
; open partial urls (e.g. gmail.com or it.wikipedia.org)
!REGEX ^[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,3}(/\S*)?$
http://||

; open windows files (from: http://stackoverflow.com/a/6416209)
!REGEX .*\\([^\\]+$)
||

; open imdb person from key (e.g. nm09123)
!REGEX ^nm\d+$
http://www.imdb.com/name/||/

; open imdb title from key (e.g. tt000435)
!REGEX ^tt\d+$
http://www.imdb.com/title/||/

; open musicbrainz page from MBID
; regex was found here: https://github.com/Dremora/foo_musicbrainz/blob/master/QueryByMBIDDialog.h
!REGEX ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$
http://musicbrainz.org/otherlookup/mbid?other-lookup.mbid=||
```