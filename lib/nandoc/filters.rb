# registers self at bottom!
module NanDoc::Filters
end

here = File.dirname(__FILE__)
require here+'/spec-doc.rb'
require here+'/filters/custom-tag.rb'
require here+'/filters/custom-tags.rb'
require here+'/filters/tag-parser.rb'
require here+'/filters/builtin-tags.rb'


module NanDoc::Filters
  class General < ::Nanoc3::Filter
    # Parses document contents for nanDoc enhancements to
    # markdown-like markup.

    # These are the supported tags:
    #   * a ruby "code fence"  (indicated with 'ruby:')
    #   * a terminal "code fence" (indicated with 'from the command line:')
    #   * example injection from unit tests
    #
    # @example the parts in the 'code fence' will be highlighted as ruby:
    #
    #     ## This Is A H2 Header Tag
    #     the following is some ruby.
    #     ruby:
    #     ~~~
    #     foo = Bar.new(:baz => 'biff')
    #     foo.run
    #     ~~~
    #
    # (The line that says "ruby:" should not appear in the output, nor
    # should the triple-tilde "fences" demarcating the code block.)
    #
    # This is designed to degrade gracefully in other contexts, if you're
    # running this only through a kramdown (or other markdown filter)
    # without the nandoc processing.
    #
    # For example if ppl are viewing your README at github, you might
    # want to indent the code inside the fence with 4 spaces so that
    # Github-Flavored Markdown will render it in html <CODE> tags. You
    # won't get the coloring but it will still hopefully look alright.
    #
    # (@todo in the future use 4-space indents instead of code fences?)
    #
    # This is comparable to Nanoc3::Filters::ColorizeSyntax but it works in
    # markdown, not html contexts. (It doesn't really matter what 'type' of
    # file it is in though, if the filter is used sufficiently early and its
    # ouptut doesn't get altered by latter filters.)
    #
    # This has less options than the Nanoc3 ColorizeSyntax filter (zero
    # being less than all positive integers): it uses
    # the ruby gem 'syntax/convertors/html' and outputs html with spans that
    # have different classes for the different types of ruby tokens.
    # (inspired by Trollop documentation.)
    #
    # Create your own stylesheet or use the trollop-like one
    # that is provided by the nanDoc site generator (see the proto/ directory
    # for the actual stylesheet, likely added by default.)
    #
    # There is no magic escaping sequences provided.  You simply cannot have
    # three tildes in your code block, unless you write the html yourself.
    #
    # This was written to be indentation aware, so that your opening fence
    # must have the same amount of indentation as your closing fence.
    #
    # (Plans for nested tags one day maybe.
    # One day maybe, nested blocks will therefor be demarcated by
    # fences with either more *or less* indenation than the demarcating
    # fences in question.(?))
    #
    # Your fences and content can have any leading amount of indent, provided
    # that the opening and closing fence have the same indent.
    # Any leading indent from the fences will be stripped from each line of
    # content provided that each line of content has at least as much indent
    # as the fences.
    #

  public

    # @param [String] content The content to filter
    # @param [Hash] params - not used
    # @return [String] The filtered content
    def run content, params={}
      CustomTags.change_item_content content
    end
  end
end

Nanoc3::Filter.register ::NanDoc::Filters::General, :nandoc
