module NanDoc
  #
  # @dependencies: none
  #

  class ParseReadme
    #
    # If you are really really crazy then you don't like
    # repeating yourself between your gemspec and your README with regard to
    # the project summary and description.
    #
    # This is a quick and dirty hack to parse your README (or similary
    # formatted file) in a really rough way for when you are building your
    # gemspec -- it doesn't use a markdown parser or whatever.  It scans the
    # README file for a line like "## Summary" and reads the next line with
    # content after it. (ditto "## Description" etc.)
    #
    # See the Rakefile of this project for example usage.
    #
    # @see note below near 'jeweler'
    #

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
      #
      # This whole thing is a ridiculously fragile and secret hack
      # that is maybe pointless @todo
      # The point is to defer opening and parsing the README file unless
      # necessary.  (But it didn't work as intended, but no big deal.)
      #
      # If you use it is is recommended that you use jeweler and the
      # gemspec:debug task to check its work.
      #

      @files = {}
      class << self
        attr_reader :files
      end
      def initialize path, section
        @path, @section = path, section
        @as_string = nil
      end
      def strip
        as_string.strip
      end
      def to_s
        as_string # can't simply alias it b/c it is private
      end
    private
      def as_string
        @as_string ||= begin
          parse = (self.class.files[@path] ||= ParseReadme.new(@path))
          parse.parse_section(@section) unless parse.respond_to?(@section)
          parse.send(@section)
        end
      end
    end
  end
end
