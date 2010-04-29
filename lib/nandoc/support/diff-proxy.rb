module NanDoc
  module DiffProxy
    include Treebis::Sopen2
    extend self
    def diff path_a, path_b, opts={}
      fail('no') unless File.exist?(path_a) && File.exist?(path_b)
      rel_to = opts.delete(:relative_to)
      path_a, path_b = relativize(rel_to, path_a, path_b) if rel_to
      opts = {'--unified=3'=>nil, '--recursive'=>nil}.merge(opts)
      args = ['diff'] + opts.each.map.flatten.compact + [path_a, path_b]
      out = err = nil
      block = proc do
        out, err = sopen2(*args)
      end
      if rel_to
        FileUtils.cd(rel_to, :verbose=>true, &block)
      else
        block.call
      end
      diff = Diff.new(out, err, args)
      if diff.error?
        return fail(diff.full_error_message){|f| f.diff = diff }
      end
      diff
    end
  private
    def fail(*a, &b)
      raise Fail.new(*a, &b)
    end
    def relativize base, path_a, path_b
      fail("KISS") unless [0,0]==[path_a, path_b].map{|x| x.index(base)}
      tail_a, tail_b = [path_a, path_b].map{|x| '.'+x[base.length..-1]}
      [tail_a, tail_b]
    end
    class Diff
      def initialize out, err, args
        @out = out
        @error = err
        @args = args
      end
      attr_reader :error
      def command
        Shellwords.join(@args)
      end
      def error?; ! @error.empty? end
      def full_error_message
        "diff failed: #{command}\ngot error: #{error}"
      end
      def ok?; ! error? end
      def to_s
        @out
      end
    end
    class Fail < RuntimeError;
      def initialize(*a,&b)
        super(*a)
        yield self if block_given?
      end
      attr_accessor :diff
    end
  end
end