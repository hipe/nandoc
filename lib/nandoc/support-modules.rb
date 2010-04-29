module NanDoc
  module CliCommandHelpers
    def command_name
      (/::([_a-z0-9]+)\Z/i =~ self.class.to_s and base = $1) or fail('no')
      base.gsub(/([a-z])([A-Z])/){ "#{$1}-#{$2}" }.downcase
    end
    def invite_to_more_command_help
      "see `nandoc help #{command_name}` for more information."
    end
    def invocation_name
      File.basename($PROGRAM_NAME)
    end
  end
  module OptsNormalizer
    def normalize_opts opts
      opts.keys.select{|x| x.to_s.index('-') }.each do |k|
        opts[k.to_s.gsub('-','_').to_sym] = opts.delete(k)
      end
    end
    nil
  end
  module PathHelper
    def assert_path name, *paths
      paths.each do |p|
        unless File.exist?(p)
          task_abort("#{name} does not exist: #{path}")
        end
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
      if msg.index("for more info") # not mr. right, mr. right now
        tail = ''
      else
        last = msg[-1].chr
        tail = ".?!".index(last) ? '  ' : ("\n"==last ? '' : '.  ')
        tail << 'Aborting.'
      end
      $stderr.puts "nanDoc: #{msg}#{tail}"
      exit 1
    end
  end
  module CliCommandHelpers
    include OptsNormalizer, TaskCommon, PathHelper
  end
  module PathHelper
    include TaskCommon
  end
end
