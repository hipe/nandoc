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
      diff = diff_class.new(out, err, args)
      if diff.error?
        return fail(diff.full_error_message){|f| f.diff = diff }
      end
      diff
    end
    def diff_class
      Diff
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
      class << self
        def default_diff_stylesheet
          @default_diff_stylesheet ||= {
            :header => [:bold, :yellow],
            :add    => [:bold, :green],
            :remove => [:bold, :red],
            :range  => [:bold, :magenta],
            :trailing_whitespace => [:background, :red]
          }
        end
        def stream_colorizer_prototype
          @stream_colorizer_prototype ||= begin
            require File.dirname(__FILE__)+'/stream-colorizer.rb'
            NanDoc::StreamColorizer.new do |sc|
              sc.stylesheet_merge(default_diff_stylesheet)
              sc.when %r(\Adiff ), :state=>:header
              sc.when(:header) do |o|
                o.style :header
                o.when %r(\A@@), :state=>:range
              end
              sc.when(:range) do |o|
                o.style :range
                o.when_not %r(\A@@), :state=>:plain
              end
              sc.when(:plain) do |o|
                o.style nil
                o.when %r(\Adiff ), :state=>:header
                o.when %r(\A\+), :state=>:add
                o.when %r(\A\-), :state=>:remove
              end
              sc.when(:add) do |o|
                o.style :add
                o.trailing_whitespace_style :trailing_whitespace
                o.when_not %r(\A\+), :state=>:plain
              end
              sc.when(:remove) do |o|
                o.style :remove
                o.trailing_whitespace_style :trailing_whitespace
                o.when_not %r(\A\-), :state=>:plain
              end
            end
          end
        end
      end
      def initialize out, err, args
        @out = out
        @error = err
        @args = args
      end
      attr_reader :error
      def colorize out, opts={}
        colorizer = self.class.stream_colorizer_prototype.spawn do |c|
          c.stylesheet_merge(opts[:styles] || {})
        end
        colorizer.filter(to_s, out)
        nil
      end
      def command
        Shellwords.join(@args)
      end
      def error?
        ! @error.empty?
      end
      def full_error_message
        "diff failed: #{command}\ngot error: #{error}"
      end
      def ok?
        ! error?
      end
      attr_reader :out
      def reject_only_in!
        @out.gsub!(/^Only in [^\n]+\n/,'')
        nil
      end
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
