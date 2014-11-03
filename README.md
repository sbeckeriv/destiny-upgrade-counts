
Bookmarklet to display upgrade material counts on the character page.
======================

I cant figure out how to create the link with markdown. Sorry.
Create a new bookmark. Use this as your url:
```
javascript:(function(){s=document.createElement('script');s.type='text/javascript';s.src='//sbeckeriv.github.io/destiny-upgrade-counts/upgrade.js?v='+parseInt(Math.random()*99999999);document.body.appendChild(s);})();
```
On a character (logged in or out, or someone elses) click the bookmark.

Greesemonkey or tampermonkey script
Thanks solrac214
```
// ==UserScript==
// @name         Bungie Gear
// @namespace    http://BungieGear/
// @version      0.1
// @description  Hope this helps ! :D
// @author       You
// @include      https?://www.bungie.net/*
// @grant        none
// ==/UserScript==

s=document.createElement('script');
 s.type='text/javascript';
 s.src='//sbeckeriv.github.io/destiny-upgrade-counts/upgrade.js?v='+parseInt(Math.random()*99999999);
 document.body.appendChild(s);
```

Example
=====================
Open
![open](http://sbeckeriv.github.io/destiny-upgrade-counts/open.png)

Not Open
![not open](http://sbeckeriv.github.io/destiny-upgrade-counts/close.png)
====================

Playing
===================
Inspect the data
```
window.upgrader
window.upgrader.items()
```
If you get a function when you expected something its most likely a knockout observerable. read more http://knockoutjs.com/documentation/introduction.html

todo
===================

Learn markdown

Make pretty

Add vault items to the list
