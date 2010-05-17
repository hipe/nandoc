## hack free zones defined

the intended audience of this document is developers of nanDoc.

out of necessity parts of this project are hack-ful zone. but parts of it are designated hack-free.  Following is a definition of what it means to be hack-free.

these guidelines are to encourage consistency, clarity of intent (self-documenting code), and code that is susceptible to being refactored (agile) with the least hassle.

(in the below as in ruby a `class` is a `module`, so 'module' also refers to class.)

a 'hack free zone' is:

  * no opening up of other people's gem classes.  this also applies to Stdlib and Corelib! (except special cases for testing.)
  * no being inside of other people's gem modules unless necessitated by their api
  * module dependencies SHOULD be cited appropriately when not explicit from requires at the top of the file
  * no policy yet on circular dependencies, but if we can avoid them, MUST not reopen classes, *or reopening of modules*, except to add modules.
  * each module MUST be defined in a file named after the module with one exception[^1]. a corollary of this is and the above is that at most one module can be defined in a file.  [^1]:The one exception to this is class-private classes or modules.
  * module hierarchy MUST be reflected in folder hierarchy
  * however, folder hierarchy CAN be semantic (logical groupings) and doesn't have to follow module hierarchy exactly, but must fall within it:
    * so, the module tree MUST fit cleanly inside the filesystem tree, while the opposite is not necessarily true
    * for example, NanDoc::StringMethods could be pulled in by `require 'nandoc/support/string-methods.rb`' but each component of the full constant name must appear in the path.
  * a module 1) SHOULD first have at least one line of documentation comment, 2) MUST then have any includes or `extend`s 3) MUST then open up the class or module's singleton class if necesssary to define any class or module methods 4) SHOULD list method definitions in alphabetical order (exception intialize with MUST (5) come at the top.)
  * every file is a leaf file or a branch file.  which it is is not discernible from looking at the filename.
    * branch files are files whose sole purpose include other files (primarily) that are children of a folder sibling to that file which shares the same name as that file without the '*.rb' extension.
    * any require statements MUST occur as the first lines in a file, unless the point below
    * if a module depends on another module:
      * if the dependee is above and/or outside and around, just include it with rubygems-style "require 'nandoc/foo/bar'".  If you don't and you instead reach up with File.expand_path(..) then a child node in the filestem tree cannot as easily move around because it is coupled with parent, uncle, or cousin node structure.
      * use the "require File.dirname(__FILE__)"-style of include only for files that require files below them.
      * modules that require other modules SHOULD require the files for those other modules _in situ_, and not rely on a parent branch-node file having knowledge of the child module's dependencies. exceptions for a branch file that can require module files that many child modules require.
      * a module can load a dependee conditionally from a method (with the `require` statement occuring in a method and not at the top of the file), but the way in which the file is required MUST follow the above guidelines.


the end.
