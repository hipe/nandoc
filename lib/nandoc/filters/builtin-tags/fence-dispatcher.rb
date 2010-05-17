require 'nandoc/html'

module NanDoc::Filters
  class FenceDispatcher
    Re = %r<
      (.*?)
      ^((?:[ ]|\t)*)((?:[a-z]|[ ])+):(?:[ ]|\t)*\n
      \2~~~(?:[ ]|\t)*\n
      (.*?)\n
      \2~~~(?:[ ]|\t)*\n
    >mx
    @fences = []
    class << self
      def =~ item_content
        Re =~ item_content
      end
      def register fent
        @fences.push fent
      end
      attr_reader :fences
    end
    def run item_content
      scn = StringScanner.new(item_content)
      out = NanDoc::Html::Tags.new
      while (match = scn.scan_until(Re))
        Re =~ match or fail("internal parse fail :(")
        noparse, indent, label, content = $~.captures
        fence_cls = self.class.fences.detect{ |fent| fent =~ label }
        if ! fence_cls
          # silently fail on unidentified blocks for now, pass them thru
          out.push_raw $~[0]
        else
          out.push_raw noparse
          fence_tag = fence_cls.new
          fence_tag.run(out, indent, label, content)
        end
      end
      out.push_raw scn.rest
      html = out.to_html
      html
    end
  end
end
