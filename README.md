Keystone is a [SIMBL][] plugin that provides keyword search for Safari. That is, you can type 'wiki Safari' into the location bar, and get the Wikipedia page for "Safari".

  [SIMBL]: http://www.culater.net/software/SIMBL/SIMBL.php


Building
-------

Keystone is currently set up to build with Xcode 3.1 or later; it is still using the Xcode 3 series in order to build for Mac OS X v10.5 (for PowerPC Macs as well as 32- and 64-bit Intel). It should be possible to build Keystone for Mac OS X v10.6 or later using Xcode 4.

Keystone has integrated support for [Sparkle][], but it's carefully cordoned off from the actual Sparkle framework to avoid conflicts if some other plugin has already loaded it.[^webkit] It should be possible to build Keystone without Sparkle support with minimal source modifications.

  [^webkit]: In particular, [WebKit nightly builds][] have been known to use Sparkle for updates.

  [Sparkle]: https://github.com/andymatuschak/Sparkle
  [WebKit nightly builds]: http://nightly.webkit.org/


Disclaimer
-------

This should go without saying, but **Keystone is basically a hack** that has broken and will continue to break with every major update to Safari. Fortunately, it should detect if it's on an untested version of Safari and warn you if things might go wrong.

For *really* major updates (e.g. new OS), SIMBL will refuse to load Keystone at all. If you want to experiment with newer versions of Safari, you can change the `MaxBundleVersion` listed under `SIMBLTargetApplications` in the Info.plist file.


Credits
-------

Keystone uses the following code snippets or libraries, from coders much wiser than I. Thank you all!

- [Dave Batton][]'s DBBackgroundView, which I've been using for a long time for drawing colors, images, and gradients behind my main content. It seems to no longer be easily available on the internet, so I'm including the compiled framework here.

- [Daniel Jalkut][]'s "gracefully ending editing" [category][NSWindow+EndEditingGracefully] on NSWindow, which saves a user's changes when a window closes.

- [Andy Matuschak][]'s [Sparkle][] update framework.

- [John Rentzsch][]'s [JRSwizzle][] for method injection, modified with some convenience macros.

  [Dave Batton]: http://twitter.com/#!/DaveBatton
  [Daniel Jalkut]: http://red-sweater.com/
  [NSWindow+EndEditingGracefully]: http://red-sweater.com/blog/229
  [Andy Matuschak]: http://andymatuschak.org/
  [John Rentzsch]: http://rentzsch.com/
  [JRSwizzle]: https://github.com/belkadan/jrswizzle


License
-------

 Copyright (c) 2009-2012 Jordy Rose

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.

 Except as contained in this notice, the name(s) of the above copyright holders
 shall not be used in advertising or otherwise to promote the sale, use or other
 dealings in this Software without prior authorization.
