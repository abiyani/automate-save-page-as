automate-save-page-as
=====================

*A quick hack for when `wget` doesn't cut it.*

**tldr; Perform browser's "Save page as" (Ctrl+S) operation from command line without manual intervention**

This small bash script *simulates* a sequence of key presses which opens a given url in the browser, save it, and close the browser tab/window. Chained together, these operations allow you to use the "Save Page As" (Ctrl+S) programtically (currently you can use either of `google-chrome` or `firefox`, and it is fairly straight forward to add support for your favorite browser).

*Examples:*
```
# Save your FB home page (assuming you are logged in)
$ ./save_page_as.bash "www.facebook.com" --destination "/tmp/facebook_home_page.html"

# Use Firefox to open a web-page and save it inside directory /tmp, but preserving the default name for the file
$ ./save_page_as.bash "www.example.com" --browser "firefox" --destination "/tmp"

# List all available command line options.
$ ./save_page_as.bash --help
```

The script needs `xdotool` installed (http://www.semicomplete.com/projects/xdotool/): `sudo apt-get install xdotool` (for Ubuntu).

*Sidenote*: My particular use case while writing this script was crawling a bunch of web pages which were rendered almost entierly on client side using lots of javascript magic (thus saving output of `wget url` was useless). Since the browser is capable of rendering those pages, and also saving the post-render version on disk (using Ctrl+S), I wrote this script to automate the process.

Suggestions and/or pull requests are always welcome!
