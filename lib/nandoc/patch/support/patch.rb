module NanDoc
  class Patch
    # don't even worry what this is.  sillyness
    class << self
      def load name
        fail("not exist: #{name}") unless File.directory?(name)
        pp = new(name)
        pp
      end
    end

    def initialize full_patch_path
      @gem_patch_name = nil
      @name = File.basename(full_patch_path)
      @out = $stdout
      @patch_path = full_patch_path
    end

    def all_paths_local
      path = full_gem_patch_path
      fail("no") unless File.directory?(path)
      paths = Dir[path+'/**/*']
      if paths.empty?
        fail("there don't appear to be any files yet for #{path}")
      end
      files = files_only_assert(paths)
      re = /\A#{Regexp.escape(path)}\/(.+)\Z/
      shorts = files.map do |thing|
        thing =~ re or fail("no: #{thing}")
        $1
      end
      shorts
    end

    def apply
      fail("sub patch not set") unless @gem_patch_name
      full_base = full_gem_patch_path
      out.puts "patching gem: #{gem_patch_name}"
      # we need it loaded before we patch it
      require gem_patch_name
      all_paths_local.each do |local|
        full = full_base + '/' + local
        out.puts "with file: #{local}"
        load full
      end
    end

    def apply_all stdout=nil
      self.out = stdout if stdout
      subpatches.each do |subpatch|
        self.gem_patch_name = subpatch
        apply
      end
    end

    def gem_patch_name= name
      unless subpatches.include?(name)
        fail("no: #{name.inspect}. expecting: ("<<subpatches.join(', ')<<")")
      end
      @gem_patch_name = name
      nil
    end

    def files_only_assert paths
      these = paths.map do |path|
        case true
         when File.directory?(path); nil
         when File.file?(path); path
         else fail("no: #{path}")
        end
      end.compact
      these
    end

    def full_gem_patch_path
      fail("no") unless @gem_patch_name
      path = @patch_path + '/' + @gem_patch_name
      path
    end

    attr_reader :gem_patch_name

    attr_accessor :name

    attr_accessor :out

    attr_accessor :patch_path

    def subpatches
      these = Dir.new(patch_path).entries.reject{ |x| x =~ /^\./ }
      these
    end

    def write_unified_diff out=$stdout, err=$stderr
      require 'nandoc/support/diff-proxy'
      fail("no gem name set") unless @gem_patch_name
      gem_root = ::Gem::GemPathSearcher.new.find(@gem_patch_name).full_gem_path
      fail("couldn't find gem root for #{@gem_patch_name}") unless gem_root
      diff = NanDoc::DiffProxy.diff(gem_root, full_gem_patch_path)
      diff.reject_only_in!
      diff.out.gsub!(/#{Regexp.escape(gem_root)}/,'a')
      diff.out.gsub!(/#{Regexp.escape(full_gem_patch_path)}/,'b')
      if out.tty?
        diff.colorize(out)
      else
        out.print diff.out
      end
      nil
    end
  end
end
