module Treebis
  #
  # experimental additions to treebis
  #

  class BlockProbe
    # if needed, etc
    def initialize(&block)
      @sexp = []
      instance_eval(&block)
    end
    attr_reader :sexp
    def method_missing name, *args
      record = [name, *args]
      @sexp.push record
      nil
    end
  end

  module PathUtils
    def undot path
      $1 if /^(?:\.\/)?(.+)$/ =~ path
    end
    def path_from_full path
      File.join(@from, undot(path))
    end
    def path_from_full_assert path
      fullpath = path_from_full(path)
      unless File.exist?(fullpath)
        name = respond_to?(:name) ? " #{self.name.inspect}" : ''
        fail <<-HERE.gsub(/^ +/, '')
          Treebis task#{name} referred to file #{path}
          that did not exist at #{fullpath}
        HERE
      end
      fullpath
    end
  end

  class Task
    include PathUtils
    alias_method :initialize_orig, :initialize
    def initialize(*a,&b)
      initialize_orig(*a,&b)
      sexp = reflection_sexp
      props = sexp.select{|x| x.first == :prop }
      set_props(props) if props.any?
    end
    def erb_variable_names
      sexp = reflection_sexp
      filenames = sexp.select{ |x| x.first == :erb }
      names = []
      filenames.each do |node|
        path = path_from_full_assert(node[1])
        names |= erb_variable_names_in_file(path)
      end
      names
    end
    def erb_variable_names_in_file path
      content = File.read(path)
      names = content.scan(/<%= *([_a-z0-9]+) *%>/).map{ |x| x[0] }
      names = names.uniq
      names
    end
    def prop *a
    end
    def reflection_sexp
      BlockProbe.new(&@block).sexp
    end
  private
    def set_props props
      sing = class << self; self end
      props.each do |prop|
        val = prop[2]
        sing.send(:define_method, prop[1]){ val }
      end
      nil
    end
    class RunContext
      def prop(*a); end
    end
  end
end
