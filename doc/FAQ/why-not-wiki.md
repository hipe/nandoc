# Q: Why not a wiki or a CMS?
<p class='answer'>A: I don't have any experience running a wiki, and only a little experience hacking on them (a lot if you count radiant cms).  With that stated:</p>

(I was going to make this a PRO's and CON's list but whether the below points are a pro or a con depends on your specific requirements[^assess].)

  * wikis are more publicly editable.  With the nanDoc, people would have to submit edits to docs patches and/or fork.

  * some wikis require dedicated server software.  NanDoc uses nanoc3 to generate a static site that you can serve with any http server that serves html documents.

  * a given wiki supports a subset of the large variety of markup languages available [^markups].  Out of the box nandoc uses kramdown (markdown), but in theory can be configured to support any of the filters that nanoc3 can support.  Out of the box nanDoc uses markdown because it seems to be a de-facto standard for this kind of thing (at least to the extend that github supports "Github Flavored Markdown").  Out of the box nanDoc uses kramdown to parse markdown because it is clean and hackable, and performance isn't important.

  * github and the like usually give you a wiki for your project.  I don't know to what extent you can get a handle on the content files for this wiki, and have them versioned, etc.

  * I spent a good amount of time making that auto-generated site-map left nav thing, and the auto-generated top-nav bread-crumber thing (which are optional).  In my experience with writing wiki pages this was always an annoyance, dealing with the information architecture of your site.  (In most wikis it seems like a page doesn't really exist unless you link to it, and out of the box most wiki's don't seem to present to you a hierarchical tree of nodes, but rather a flat list of documents that can be linked to; or more accurately don't exist until they are linked to.)

  * More generally the thing about nanDoc is that it can allow you to couple tightly your code and your docs, so for example if someone is watching your project on github they will get notified all the same when either your code or or you docs are updated.


[^assess]: coming soon!
[^markups]: @todo make a nice comparison matrix of these somewheres.
