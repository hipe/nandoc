### Abstract

The target audience of this document is developers *of* nanDoc, not developers using nanDoc.

This document introduces the use of [treebis](http://treebis.hipeland.org) tasks for use in representing site prototypes and generating prototype sites; and presents three implementation alternatives of NanDoc site creation, and then explains why we are going with the one we are going with at the time of this writing.  (It was also a chance for me to experiment with markdown footnotes!)


### Prototypes

Almost each folder in this folder is a 'prototype' nanDoc installation.  Most users will only ever use the `default` prototype and not worry about other prototypes. (maybe.)

The folder called 'misc' holds one-off templates for ad-hoc stuff, maybe for helpers etc.

The result of each such prototype is comparable to the filetree you get from a default nanoc 'create_site' command, but altered accordingly to be a NanDoc site, whatever that will come to mean.


### Changesets through Treebis

The prototype site(s) in this folder is probably expressed as a cangeset to an existing default filetree created by `nanoc create_site <my-site>`.  Given that the default NanDoc site is rougly 90% the same as a default Nanoc3 site ATTOTW, the author felt that it would be best to represent the default NanDoc site as a diff of the default Nanoc site.[^1]

[^1]: At such time as this percentage drops significantly we will reconsider this decision. -- @todo this is no longer the case.

Thus the changesets here are the minimal readable expression of changes we want to make to a default nanoc site tree, to alter it to be a default NanDoc
site tree.  These changesets are expressed using a Treebis 'patch' which is some files along with a Treebis task.  (See documentation there for gory details.)

One big unified diff would have worked to this end, but the author felt that a Treebis patch was more readable and navigable, especially through the perspective of a VCS, which will now be carrying diffs of diffs.


#### Caveats and notes

An alternative would be to represent the files we need in our default site tree in their entirety here, and not rely on the nanoc create_site command.[^2] This would have the advantage that it would be less fragile than the current implementation, which will break whenever there are significant changes to the defult site from Nanoc.  However the current implementation has the advantage that A) it might pick up future changes to the nandoc site provided our patch doens't break on it, and B) we get this de-facto early warning mechanism about changes to the default nandoc app site content and structure.

[^2]: We may still rely on the command but not the files it ouputs.

In other words, the disadvantage is that this goes stale loudly.  The advantage is that it goes stale loudly.
