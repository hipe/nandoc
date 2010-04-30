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
      nil
    end
    def unnormalize_opt_keys keys
      keys.map{|x| unnormalize_opt_key(x)}
    end
    def unnormalize_opt_key key
      "--#{key.to_s.gsub('_','-')}"
    end

    #
    # only call this if you are like a ::Cri::Command object with
    # all the nanDoc hacks. ick.  This is a temprary hack.  Trollop et al
    # do this better.
    #
    def exclusive_opt_flags opts, &block
      Exclusive.new(&block).parse(self, opts)
    end

    class Exclusive
      include OptsNormalizer
      def initialize &block
        @exclusive_flag_keys = nil
        @default_short = nil
        @default_key = nil
        @notice_stream = $stderr
        instance_eval(&block)
        fail('definition block needs at least flags()') unless
          @exclusive_flag_keys
      end
      def flags * exclusive_flag_keys
        @exclusive_flag_keys = exclusive_flag_keys
      end
      # params: [short_name_string] name_key
      def default *a
        if a.first.kind_of?(String)
          @default_short = a.shift
        end
        if a.first.kind_of?(Symbol)
          @default_key = a.shift
        else
          fail("bad args: #{a.first.inspect}")
        end
        fail("extra args: #{a.inspect}") if a.any?
      end
      def notice_stream mixed
        @notice_stream = mixed
      end
      def parse cmd, opts
        these = @exclusive_flag_keys & opts.keys
        if these.empty? && @default_key
          if @notice_stream
            msg =
            ["using default: "+unnormalize_opt_key(@default_key),
              @default_short ? "(#{@default_short})" : nil
            ].compact.join(' ')
            @notice_stream.puts msg
          end
          these.push(@default_key)
        end
        if these.size > 1
          flags = unnormalize_opt_keys(@exclusive_flag_keys)
          cmd.task_abort <<-ABORT.gsub(/^  */,'')
            #{flags.join(' and ')} are mutually exclusive.
            usage: #{cmd.usage}
            #{cmd.invite_to_more_command_help}
          ABORT
        end
        these.first
      end
    end
  end
  module PathHelper
    def assert_path name, *paths
      paths.each do |p|
        unless File.exist?(p)
          task_abort("#{name} does not exist: #{p}")
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
