# Frequently Asked Questions
<span style='font-size: 0.9em'><em>I can't walk 2 blocks outside my home without some stranger coming up to me and asking me one or more of these questions.</em></span>

## Q: Why not jekyll?
<p class='answer'>A: I started this knowing nothing about jekyll.  nanoc3 found me and i was already acquainted with its author and i liked what i saw so i just ran with it without doing a broad survey of other solutions.  At the time of this writing i still don't really know jekyll. @todo</p>

## Q: What about a wiki or a CMS?
<p class='answer'>A: Yeah that's sorta what this feels like, isn't it.  I don't know!  What about it?  Musings <a href='why-not-wiki/'>here</a>.</p>

## Q: Why do you keep calling nanDoc a hack?
<p class='answer'>A: nanoc3 although awesome didn't meet the first requirement of nanDoc which was to use as source content a README (and other assets) that live at the root of your project (e.g. gem); as opposed to living in <code>my-site/content</code> folder the way nanoc3 wants it.  Nanoc3 wants it this way for good reason, as it turns out, because it takes some work to deal with pulling content from arbitrary folders and files; and to bend Nanoc3 to do this has resulted in a fragile rube-goldberg machine.
</p>

(It bears mentioning that those parts of nanDoc not concerned with the above are not as fragile and quite awesome.)

## Q: Why the hell do you want to do it this way? Why so many hoops?
<p class='answer'>A: Because I hate hate hate it when my documentation can't keep up with the way my code works, or worse lies about it; and I love love love the idea of generating as much as possible good documentation from good tests.</p>

I heard that with BSD/GNU/unix tools you couldn't release an alpha version of the thing without first finishing your manpage [citation needed].  In many responsible shops you can't commit your code unless it's covered by tests and doesn't break the other tests.  With nanDoc you can't build your documentation unless your (relevant) tests pass, and it's not easy to build good documentation without them.  I like it this way.  If you don't, read these nikes!

## Q: But what about rdoc/yard?
<span class='answer'>A:</span> Rdoc/yard are important tools that do what they do well. [^notyet] NanDoc is certainly not a replacement for them.

Rdoc/yard are good at generating API documentation and that's what they should be used for.  NanDoc is for creating a narrative story, (indeed a grand metanarrative in the spirit of Lyotard,[^lyotard]) with a beginning middle and end (and hopefully some pretty pictures along the way); and grabbing pieces from your tests to use as examples (illustrations) in the story; or possibly creating taxonomies of such narratives.[^yard]

## Q: What about (python's) doctest?
<p class='answer'>A: Python's doctest seems nifty and was one of the inspirations for this.  However the overriding convention of the day seems to be to let your tests ("specs") live in their own files; and I like it this way so that when I'm looking at code I can read code and not let it get cluttered by natural language explaining (or possibly lying about) what the code <em>should</em> do.</p>

Whereas doctest is about writing comments that have embedded code that makes a test that tells a story, nanDoc is about taking your tests that tell a story and injecting parts of them into your (narrative) documentation.

Recent-esque trends in some parts (behavior-driven development, user-stories, cucumber et-al) have fed into the inpiration for this; but they don't run all the way to the finish line which is to give an accessible, natural language context to their stories beyond what code is capable of or should be used for.

## Q: Could this idea behind nanDoc somehow be extended further with unit testing frameworks that bend themselves around telling a story?
<span class='answer'>A:</span> Yes. [^cucumber][^dtdsl]


## Q: Will NanDoc be useful for generating docs for my Rails app or my Restful API, or my Ruby library?
<p class='answer'>A: No, as it is I don't really think so.  For now it seems to be focused on writing narratives to explain command-line apps.  I need to think about this!  (hrm oops drats.)
</p>

Wait, come to think of it, yes maybe.  If generating a static website from markdown-formatted files that live in arbitrary locations in your project is exactly what you have in mind, then nanDoc is your new best friend.


## Q: But what about LaTeX?
<p class='answer'>A: If you know what LaTeX is you should put this book down right now and continue writing your own! (I'm lookin' at you, Ramaze!) (heh or not it has its disadvantages n'est-ce pas?) I like markdown-esque syntax because it's human readable as a plain-text document and it gets "this" job done.  But of course it can't do everything.  If you were to try and write a nanoc3 filter that reads TeX and outputs html/css/assets then you my friend are hereby being called a black pot by one crazy kettle.</p>

This is me trying not to think about generating a pdf from a nanDoc-generated site.  (I guess the first question would be, "why?").

Also kramdown (that nanDoc uses) apperantly already supports LaTeX [math blocks](http://kramdown.rubyforge.org/syntax.html#math-blocks) which (like the safety cushion in an aiplane that can also be used as a flotation device) I don't ever plan on using but am glad exist.

<br />
<br />
<br />
<hr />
## Die Fußnoten

[^notyet]:  At least, I think rdoc and yard are important tools. I haven't really gotten to know them yet at the time of this writing.  (I do know yard's author to be sharp, however.)

[^yard]: Up next and pretty soon here, i'm going to look into generating sister taxonomies from the api docs generated by yard and having them live next to the web content generated by markdown files.  (Nokogiri's and the prettier but now hard to find site for Hpricot are good examples of this.)  (Hpricot's now defunct site was a big inspiration for this.  Just perfect.)


[^lyotard]: Ok actually he probably would [not](http://en.wikipedia.org/wiki/Metanarrative#Replacing_grand.2C_universal_narratives_with_small.2C_local_narratives) write one, would that poststructuralists wrote software, which is to say that they don['](http://rubyconf2007.confreaks.com/d1t1p1_what_makes_code_beautiful.html)t.


[^cucumber]: The first time I tried using cucumber it annoyed me the way rspec annoys people who are used to vanilla Test::Unit tests.  But potential seems to be there (and has been surely been explored to a fuller extend elswhere [citation needed]) to do something like generating docs from these kind of tests.


[^dtdsl]: Or you might be like Dave Thomas (whoever he is) and [hate all DSL's](http://pragdave.blogs.pragprog.com/pragdave/2008/03/the-language-in.html)
