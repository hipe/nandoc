module NanDoc
  module OptsNormalizer
    def normalize_opts opts
      opts.keys.select{|x| x.to_s.index('-') }.each do |k|
        opts[k.to_s.gsub('-','_').to_sym] = opts.delete(k)
      end
    end
  end
  module StringFormatting
    def basename_no_extension str
      /([^\/\.]+)(?:\.[^\.\/]+)?\Z/ =~ str ? $1 : nil
    end
    def indent str, indent
      str.gsub(/^/, indent)
    end
    def no_blank_lines str
      str.gsub(/\n[[:space:]]*\n/, "\n")
    end
    def no_leading_ws str
      str.gsub(/\A[[:space:]]+/, '')
    end
    def unindent str, by
      str.gsub(/^#{Regexp.escape(by)}/, '')
    end
  end
  module TaskCommon
    def task_abort msg
      tail = (".?!".index(msg[-1].chr) ? '  ' : '.  ') << 'Aborting.'
      $stderr.puts "NanDoc: #{msg}#{tail}"
      exit 1
    end
  end
end
