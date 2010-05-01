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
  module StringFormatting; end
  module OptsNormalizer
    def normalize_opts opts
      opts = opts.dup
      opts.keys.select{|x| x.to_s.index('-') }.each do |k|
        opts[k.to_s.gsub('-','_').to_sym] = opts.delete(k)
      end
      opts
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
    class OptEnum
      include OptsNormalizer, StringFormatting
      def initialize(&block)
        instance_eval(&block)
      end
      def command cmd
        @command = cmd
      end
      def default str
        @default = str
      end
      def name name
        @name = name
      end
      def parse opts
        found = nil
        if opts.key?(@name)
          v = opts[@name]
          re = /\A#{Regexp.escape(v)}/
          founds = @values.grep(re)
          case founds.size
            when 0; invalid(v)
            when 1; found = founds.first
            else found = founds.detect{|f| f==v} or too_many(founds)
          end
        elsif(@default)
          found = @default
        else
          found = nil
        end
        opts[@name] = found if found # normalize short versions
        found
      end
      def values *v
        v = v.first if v.size==1 && Array === v
        @values = v
      end
    private
      def coda
        "usage: #{@command.usage}\n#{@command.invite_to_more_command_help}"
      end
      def invalid val
        @command.task_abort("invalid value #{val.inspect} for "<<
          "#{long_name}. #{valid_values_are}\n#{coda}")
      end
      def long_name
        unnormalize_opt_key(@name)
      end
      def too_many these
        @command.task_abort("did you mean " <<
          oxford_comma(these,' or ', &quoted)<<" for #{long_name}?\n#{coda}")
      end
      def valid_values_are
        "valid values are " << oxford_comma(@values,&quoted)
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
    def oxford_comma items, final = ' and ', &quoter
      items = items.map(&quoter) if quoter
      these = []
      these.push final if items.size > 1
      these.concat(Array.new(items.size-2,', ')) if items.size > 2
      these.reverse!
      items.zip(these).flatten.compact.join
    end
    def quoted
      proc{|x| "\"#{x}\"" }
    end

    #
    # must respond to tab() and tabs()
    # reindent a block by striping leading whitespace from lines evenly
    # and then re-indenting each line according to our indent.
    # this could be simpler, it has been more complicated
    # we do it languidly because we can
    #
    def reindent h1, offset=0
      indent_by = tab * (tabs+offset)
      unindent_by = (/\A([[:space:]]+)/ =~ h1 && $1) or fail('re fail')
      h2 = no_blank_lines(h1) # careful. will mess up with <pre> etc
      return h2 if unindent_by == indent_by
      h3 = unindent(h2, unindent_by)
      h4 = indent(h3, indent_by)
      h4
    end

    def unindent str, by
      str.gsub(/^#{Regexp.escape(by)}/, '')
    end
  end
  module SecretParent
    #
    # set parent attribute without it showing up in inspect() dumps
    #
    def parent= mixed
      fail("no clear_parent() available yet.") unless mixed
      @has_parent = !! mixed
      class << self; self end.send(:define_method, :parent){mixed}
      mixed # maybe chain assignmnet of 1 parent to several cx at once
    end
    def parent?
      instance_variable_defined?('@has_parent') && @has_parent # no warnings
    end
    def parent
      nil
    end
  end
  module SharedAttrReader
    #
    # this is a specialized form of delegator pattern: let one object
    # use the responses from another object for a set of accessors
    #
    def shared_attr_reader *list
      fail('no inehiritance yet') if method_defined?(:shared=)
      sm = Module.new
      name = self.to_s+'::SharedAttrReaders'
      sing = class << sm; self end
      sing.send(:define_method, :name){name}
      sing.send(:alias_method, :inspect, :name)
      list.each do |attrib|
        sm.send(:define_method, attrib){ shared.send(attrib) }
      end
      fail('no') if method_defined?(:shared)
      define_method(:shared){ self }
      define_method(:shared=) do |source|
        sing = class << self; self end
        sing.send(:define_method, :shared){ source }
        sing.send(:include, sm) # wow cool that this works w/o having
                                # to Module#undef_method
        source
      end
      nil
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
