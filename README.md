
Bookmarklet to display upgrade material counts on the character page. 
======================

I cant figure out how to create the link with markdown. Sorry.
Create a new bookmark. Use this as your url:
```
javascript:(function(){s=document.createElement('script');s.type='text/javascript';s.src='http://sbeckeriv.github.io/destiny-upgrade-counts/upgrade.js?v='+parseInt(Math.random()*99999999);document.body.appendChild(s);})();
```

On a character (logged in or out, or someone elses) click the bookmark. 

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
```

todo:

Learn markdown

Clean up coffeescript/javascript

Make pretty

Add vault items to the list

Remove other items (ships and stuff)

Add a opps the code broke. Maybe they updated the site?

Add a check to see if its already running. 
