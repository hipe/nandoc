# NanDoc

## Commands

### `diff`

The diffing command is intended primarily as an internal development tool for me, in order to push and pull assets between my compiled site (the `my-site/output` folder), my content files of my site, (the `my-site/content` folder), and the assests modeled in the nanDoc site prototypes.


<div class='sidebar-right'>

<h4>push and pull?</h4>

<p>
<code>push</code> and <code>pull</code> don't have the typicical frame of reference here since there's no central server, just nodes on your filesystem.  But their usage here corresponds to whether the direction in the flow of information is going <em>with</em> or <em>against</em> the "typical" direction.
</p>

<p>
The typical direction is <em>from</em> the nandoc site prototype <em>to</em> your <code>my-site/content</code> directory (when you first create the nanDoc site), and then (with the nanoc3 <code>compile</code> command) <em>from</em> the content directory _to_ the output directory.  When you are changing files <em>down</em>on (or <em>later</em> in, or <em>to the right</em> of) this chain with new information from files <code>up</code> in this chain, i call it "<em>pushing</em>", else "<em>pulling</em>".  I think.
</p>

</div>


However, end users may find this command useful for the following:

* fix your css files in your output/ directory, then once you get them right, pull that change back into your content/ directory, so the next time you `nandoc co` (compile) it will create css files with this new css. (@todo what is the normal nanoc workflow for this?)

* if you get a new version of nanDoc or somehow elsewise have a new site prototype, you can review and push changes from the new assets in the prototype to the assets in your `content/` directory.


#### pulling css from output back to content folders

This is most commonly what I use diffing for, so it is the easiest to type out, because the default destination node is the content directory, and the default subset node to compare is the css folder.

<div class='clear'></div>


For now, I must refer you to this jibber jabber:

from the command line:
~~~
~/my-gem/my-site/ > nandoc help diff
@todo
~~~

gotta go!

&#10087;