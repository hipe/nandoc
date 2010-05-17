module NanDoc::SpecDoc::Playback
  module PlaybackMethods
    def get_tag_filter record
      record.first == :class or fail("not a class record #{record.inspect}")
      ret = nil
      mixed = record[1]
      if mixed.kind_of?(Class)
        if self.kind_of?(mixed)
          ret = self
        else
          ret = mixed.get_tag_filter
        end
      else
        pb = NanDoc::SpecDoc::Playback
        cls = pb.const_defined?(mixed) && pb.const_get(mixed)
        # we need the extra check below for Terminal,
        # which in some cases can have sub-files/modules loaded w/o it
        # there is room to make more advanced loaders, e.g. with ::Foo::Bar
        if ! ( cls && cls.respond_to?(:get_tag_filter) )
          thing = mixed.gsub(/([a-z])([A-Z])/){ "#{$1}-#{$2}" }.downcase
          require "nandoc/spec-doc/playback/#{thing}.rb"
        end
        cls = pb.const_get(mixed)
        ret = cls.get_tag_filter
      end
      ret
    end

    def run_sexp_with_handlers doc, scn
      these = handlers
      while node = scn.current
        if these.key?(node.first)
          record = these[node.first]
          break if record.first == :stop
          handler = get_tag_filter(record)
          handler.send(record[2], doc, scn)
        else
          break
        end
      end
      nil
    end
  end
end
