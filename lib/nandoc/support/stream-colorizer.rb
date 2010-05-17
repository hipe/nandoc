module NanDoc
  class StreamColorizer
    module RuleList; end
    module SecretParent; end
    include RuleList;
    def dup
      other = self.class.new
      other.stylesheet = stylesheet.dup
      other.rule_list = rule_list.dup
      other.state_set = state_set.dup
      other
    end
    def initialize(*a, &b)
      rule_list_init
      @stylesheet = {}
      if a.any? || block_given?
        merge(*a, &b)
      end
    end
    attr_writer :rule_list
    def filter string, out
      found = rule_list.detect{ |x| x.match(string) }
      use_state = found ? found.state : :plain
      state = get_state_or_fail(use_state)
      string = string.dup
      while next_state_name = state.process(string, out)
        state = get_state_or_fail(next_state_name)
      end
      nil
    end
    def merge(&block)
      yield(self) if block_given?
      self
    end
    def spawn(*a, &b)
      other = dup
      other.merge(*a, &b)
      other
    end
    attr_writer :state_set
    attr_accessor :stylesheet
    def stylesheet_merge other
      @stylesheet.merge!(other)
    end

  #
  # api private classes:
  #

    module RuleList
      def rule_list_init
        @rule_list = []
        @state_set = {}
      end
      def add_regex_rule re, opts
        fail("no") unless opts[:state]
        @rule_list.push RegexRule.make(re, opts[:state], {})
      end
      def add_regex_rule_neg re, opts
        fail("no") unless opts[:state]
        @rule_list.push RegexRule.make(re, opts[:state], {:neg=>true})
      end
      def define_state name, &block
        state = State.new(self, name, &block)
        fail("no") if @state_set.key?(state.name)
        @state_set[state.name] = state
      end
      def get_state_or_fail name
        state = @state_set[name]
        state or fail("no such state: #{name.inspect}")
        state
      end
      attr_reader :rule_list
      def when(re_or_symbol, opts=nil, &block)
        if re_or_symbol.kind_of?(::Regexp) && Hash===opts && ! block_given?
          add_regex_rule(re_or_symbol, opts)
        elsif re_or_symbol.kind_of?(Symbol) && opts.nil? && block_given?
          define_state(re_or_symbol, &block)
        else
          fail("unrecongized signature: `#{self.class}#when("<<
            "[#{re_or_symbol.class}],[#{opts.class}],[#{block.class}])")
        end
      end
      def when_not re, opts
        add_regex_rule_neg re, opts
      end
      attr_reader :state_set
    end
    class RegexRule
      class << self
        def make regex, state, opts
          if opts[:neg]
            RegexRuleNeg.new(regex, state)
          else
            RegexRule.new(regex, state)
          end
        end
      end
      def initialize regex, state
        @regex = regex
        @state = state or fail('no')
      end
      attr_reader :regex, :state
      def match str
        @regex =~ str
      end
    end
    class RegexRuleNeg < RegexRule
      def match str
        ! super
      end
    end
    class State
      include RuleList, Treebis::Colorize, NanDoc::SecretParent
      def initialize parent, name, &block
        self.parent = parent
        rule_list_init
        fail('no') unless Symbol === name
        @name = name
        @style = nil
        @trailing_whitespace_style = nil
        block.call(self)
      end
      attr_accessor :name
      def next_line str, alter=false
        res = false
        if str == ''
          nil
        elsif alter
          if /\A([^\n]+)(?:\n?)(.*)\Z/m =~ str
            res = $1
            str.replace($2)
          else
            fail("fail: #{str.inspect}")
          end
        else
          if /\A([^\n]+)/ =~ str
            res = $1
          else
            fail("fail: #{str.inspect}")
          end
        end
        res
      end
      def process string, out
        ret = nil
        while line = next_line(string)
          if other = rule_list.detect{|x| x.match(string)}
            next_state_name = other.state
            ret = next_state_name
            break
          else
            next_line(string, true) # alter string
            use_line = nil
            if @trailing_whitespace_style
              /\A(|.*[^[:space:]])([[:space:]]*)\Z/ =~ line or fail('oops')
              head, tail = $1, $2
              colored_head = colorize(head, *colors)
              use_line = colored_head.dup
              unless tail.empty?
                ws_style = parent.stylesheet[@trailing_whitespace_style] or
                  style_not_found_failure('@trailing_whitespace_style')
                colored_tail = colorize(tail, *ws_style)
                use_line.concat colored_tail
              end
            else
              use_line = colorize(line, *colors)
            end
            out.puts use_line
          end
        end
        ret
      end
      def colors
        @colors ||= begin
          if style.nil?
            []
          else
            parent.stylesheet[style] or style_not_found_failure
          end
        end
      end
      def style *a
        case a.size
        when 0; @style
        when 1; @style = a.first
        else fail('no')
        end
      end
      def trailing_whitespace_style *a
        case a.size
        when 0; @trailing_whitespace_style
        when 1; @trailing_whitespace_style = a.first
        else fail('no')
        end
      end
      def style_not_found_failure which = '@style'
        value = instance_variable_get(which)
        fail("#{which} not found: #{value.inspect}")
      end
    end
  end
end
