module NanDoc
  class ParseReadme
    def initialize(path=nil, &block)
      @parsed_content = {}
      @lines = nil
      @path = path and get_lines!
      instance_eval(&block) if block_given?
    end
    class << self
      alias_method :parse, :new
      def description file
        DeferredParse.new(file, :description)
      end
      def summary file
        DeferredParse.new(file, :summary)
      end
    end
    attr_accessor :lines
    def path name
      @path = name
      get_lines!
      name
    end
    def parse_section *names
      names.each do |name|
        re = /\A#* ?#{Regexp.escape(name.to_s)}\Z/i
        idx = (@lines.index{|x| re =~ x } or
          fail("#{name.to_s.inspect} section not found in #{path}")) + 1
        idx += 1 while @lines[idx] && /\A[[:space:]]+\Z/ =~ @lines[idx]
        line = @lines[idx] or
          fail("couldn't find content following #{name.to_s} section")
        @parsed_content[name] = line.strip
        class << self; self end.send(:define_method, name) do
          @parsed_content[name]
        end
      end
      nil
    end
    alias_method :parse_sections, :parse_section
  private
    def get_lines!
      @lines = File.open(@path).lines.map
    end
    class DeferredParse
      # this whole thing is a ridiculously fragile and secret hack
      # that is pointless @todo
      @files = {}
      class << self
        attr_reader :files
      end
      def initialize path, section
        @path, @section = path, section
      end
      def strip
        parse = (self.class.files[@path] ||= ParseReadme.new(@path))
        parse.parse_section(@section) unless parse.respond_to?(@section)
        parse.send(@section)
      end
    end
  end
end
