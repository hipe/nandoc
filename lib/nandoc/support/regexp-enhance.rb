module NanDoc
  module RegexpEnhance
    #
    # Just gives pre-1.9 regexes the ability to have named captures
    #
    # Usage:
    #
    #   re = /(foo*)bar(baz*)/
    #   RegexpEnhance.names(re, :the_foo, :the_baz)
    #   md = re.match("fooobarbazzzz")
    #   md[:the_foo] # => 'fooo'
    #
    class << self
      def names re, *list
        to(re) do |re|
          re.names(*list)
        end
        nil
      end
      def to re, &block
        re.extend(self)
        re.regexp_enhance_init
        block.call(re)
        nil
      end
    end
    def regexp_enhance_init
      @names ||= []
      class << self
        alias_method :orig_match, :match
        def match str
          md = super
          MatchData.to(md, self) if md
          md
        end
      end
    end
    def match_assert str, name=nil
      match(str) or begin
        use_name = name || "/#{source}/"
        fail("#{use_name} failed to match #{str.inspect}")
      end
    end
    def names *list
      if list.any?
        @names = list
      else
        @names
      end
    end
    module MatchData
      class << self
        def to(md, re)
          md.extend self
          md.match_data_enhanced_init(re)
          nil
        end
      end
      def match_data_enhanced_init re
        @names = re.names
        class << self # @todo see if this doesn't break by moving defs out
          alias_method :fetch_orig, :[]
          attr_reader :names
          def [](mixed)
            return fetch_orig(mixed) unless mixed.kind_of?(Symbol)
            fail("no such named capture: #{mixed.inspect}") unless
              @names.include?(mixed)
            offset = @names.index(mixed) + 1
            fetch_orig offset
          end
        end
      end

      #
      # @return [Hash] of the named captures in the MatchData
      #
      def to_hash
        Hash[ names.map{ |n| [n, self[n] ] } ]
      end
    end
  end
end
