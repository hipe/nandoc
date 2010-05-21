require 'strscan'
module NanDoc::Filters
  class SeeTest
    include NanDoc::StringMethods
  private
    Re = %r{\(see:[ ]*(?:spec|test)[^\s]+
      (?:
        [ ]*
        (?:--?|/)
        [ ]*
        (?:
          '[^']*' |
          "[^"]*" |
          [^\s'"]+
        )
      )+ \)[ ]*\n
    }x
    Re2 =  /(.*)(#{Re.source})/mx
    class << self
      def =~ item_content
        Re =~ item_content
      end
    end
  public
    def run item_content
      scn = MyStringScanner.new(item_content)
      doc = NanDoc::Html::Tags.new
      while (match = scn.scan_until(Re))
        noparse, parse = Re2 =~ match && $1, $2
        doc.push_raw noparse
        scn2 = MyStringScanner.new(parse)
        scn2.skip(/\(see: */)
        path = scn2.scan_assert(/[-\w]+\.\w+/i, 'path')
        things = []
        loop do
          scn2.skip(%r<\s*(?:--?|/)\s*>)
          this = scn2.scan(/ '[^']*' | "[^"]*" | [^\s'"]+ /x) or begin
            fail("internal parse fail near #{scn2.rest.inspect}")
          end
          things.push unquote(this)
          scn2.skip(/\)\s*/)
          scn2.eos? and break
        end
        playback = NanDoc::SpecDoc::Playback::Method.new(path, things)
        playback.make_html doc
      end
      doc.push_raw scn.rest
      html = doc.to_html
      html
    end
    # push it up if desired
    class MyStringScanner < StringScanner
      def scan_assert foo, name=nil
        ret = scan(foo)
        unless ret
          use_name = name ? "#{name} (/#{foo.source}/)" :
            "/#{foo.source}/"
          fail("Unable to find #{use_name} in #{rest.inspect}")
        end
        ret
      end
    end
  end
end
