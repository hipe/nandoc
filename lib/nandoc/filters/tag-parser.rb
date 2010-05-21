module NanDoc::Filters
  class CustomTag # we are just (re) opening this class

    class TagParser
      # treetop?
      #
      def initialize
        @last_failure_lines = nil
      end
      def failure_lines *ignored
        @last_failure_lines
      end
      def get_symbol mixed
        if mixed.kind_of?(ParserSymbol)
          mixed
        elsif :start == mixed
          name = symbols[:start]
          sym = get_symbol_with_name(name)
        elsif :end == mixed
          sym = EndSymbol
        elsif mixed.kind_of?(Array)
          sym = Seq.new(self, mixed)
        else
          sym = get_symbol_with_name(mixed)
        end
        sym
      end
      def get_symbol_with_name name
        thing = symbols[name] or fail("Symbol not found: #{name.inspect}")
        sym = case thing
          when Hash
            RegexpSymbol.new(self, thing, name)
          else
            fail("no: #{thing.inspect}")
        end
        sym
      end
      def get_start_symbol
        get_symbol(:start)
      end
      # return tree or (nil and set failure lines)
      def parse str
        sym = get_start_symbol
        scn = StringScanner.new(str)
        sex = []
        fails = []
        ok = true
        while sym
          ch_ret = sym.parse(scn, sex, fails)
          case ch_ret
          when ParserSymbol
            sym = ch_ret
          when false;
            ok = false
            break
          when true;
            ok = true
            break
          else
            fail("unhandled case: #{sym.inspect}")
          end
        end
        if ok
          sex
        else
          @last_failure_lines = fails
          nil
        end
      end
      def symbols
        @symbols ||= begin
          self.class.const_get(:Symbols) or
            fail("Symbols constant not found in #{self.class}")
        end
      end
      module ParserSymbol
        def secret_grammar grammar
          sing = class << self; self end
          kelsey = grammar
          sing.send(:define_method, :grammar){ kelsey }
        end
      end
      class EndSymbolClass
        include ParserSymbol
        def parse scn, sex, fails
          puts "END is parsing #{scn.rest.inspect}"
          ret = nil
          if scn.rest == ""
            ret = true
            sex.push [:end]
          else
            fails.push "expecting end of input near #{scn.rest.inspect}"
            ret = false
          end
          ret
        end
      end
      EndSymbol = EndSymbolClass.new
      class RegexpSymbol
        include ParserSymbol
        def initialize(grammar, hash, name)
          secret_grammar grammar
          @desc = hash[:desc] or fail("no")
          @re   = hash[:re]   or fail("no")
          @next = hash[:next]
          @no_sexp = hash[:no_sexp]
          self.name = name
        end
        attr_reader :desc
        attr_accessor :name
        attr_reader :re
        attr_reader :next
        def next_symbol_or_nil
          self.next and grammar.get_symbol(self.next)
        end
        # @return nil iff you succeed and have no next
        # @return next parser if you succeed and have a next parser
        # @return false if you fail
        def parse scn, sex, fails
          print "[#{name.inspect}] is parsing #{scn.rest.inspect}"
          my_ret = nil
          if matched = scn.scan(re)
            sex.push([name, matched]) unless @no_sexp
            my_ret = next_symbol_or_nil
            my_ret ||= true # assume no next and we parsed it ok
            puts " matched: #{matched}"
          else
            fails.push "expecting #{desc} near #{scn.rest.inspect}."
            my_ret = false
            puts " not found"
          end
          my_ret
        end
      end
      # union production
      class Or < Array
        include ParserSymbol
        class << self
          def [](*arr)
            new(arr)
          end
        end
        # def parse scn, sex, fails
        #   debugger; 'x'
        #   my_fails = []
        #   my_ret = nil
        #   found = false
        #   self.each do |child|
        #     ch_fails = []
        #     ch_ret = child.parse(scn, sex, ch_fails)
        #   end
        # end
      end
      # concatentation production
      class Seq
        include ParserSymbol
        def initialize grammar, arr
          secret_grammar grammar
          @arr = arr
          @parsers = Array.new(arr.size)
          @done = false
        end
        def get_parser_at offset
          @parsers[offset] ||= begin
            def_thing = @arr[offset]
            sym = nil
            if def_thing
              sym = grammar.get_symbol(def_thing)
            end
            sym
          end
        end
        def parse scn, sex, fails
          my_ret = nil
          current = 0
          last = @arr.size - 1
          sym = get_parser_at(current)
          while sym
            puts "sequence at #{current} about to parse #{scn.rest.inspect}"
            ch_ret = sym.parse(scn, sex, fails)
            if ch_ret.kind_of?(ParserSymbol)
              sym = ch_ret
            elsif ch_ret == false
              sym = false
              my_ret = false
              break
            elsif ch_ret == true
              current += 1
              sym = get_parser_at(current)
            else
              fail("don't know what to do with this: #{ch_ret.inspect}")
            end
          end
          if my_ret.nil?
            if current <= last
              fail("what happened?")
            else
              my_ret = true
            end
          end
          my_ret
        end
      end
    end
  end
end
