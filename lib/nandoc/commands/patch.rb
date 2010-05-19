module NanDoc::Commands
  class Patch < ::Cri::Command
    include NanDoc::Cli::CommandMethods
    include NanDoc::Cli::OptionMethods

    def name; 'patch' end

    def aliases; [ 'p' ] end

    def short_desc
      "#{NanDoc::Config.option_prefix}very private -- make patches *for* nanoc3/asdf"
    end

    def long_desc
      <<-LONG_DESC.gsub(/\n +/,' ')
      Break up some of our nanoc3/asdf hacks into separate folders
      that are grouped thematically (per change) and then one level
      under that, per gem (nanoc3 and adsf)

      All the files we need to change in each gem will have a copy-pasted
      version under there, with the appropriate changes made.

      This way we can in theory go about our work without having
      to patch the actual gems we are using (rather we just load
      each file in our 'patch' folder to redefine module methods as
      necessary), but if we want we can generate a patch file from these
      to send to the authors of the projects if desired.

      This will also let us see when the target gems have changed
      beyond what we expect.

      LONG_DESC
    end

    def usage;
    'nandoc patch [<patch-name> [<gem-name>]]'
    end

    def option_definitions
      [
      ]
    end

    def run opts, args
      opts = normalize_opts opts
      return list_patches if args.empty?
      patch = get_patch_or_fail(args) or return
      patch = get_patch_object(patch, args) or return
      patch.write_unified_diff(out)
      nil
    end

  private

    # @pre: @param [Array] args is non-empty array
    def get_patch_or_fail args
      name = args.shift
      use_name = find_one(name, get_patches)
    end

    def get_patches
      these = Dir.new(patch_path).entries.reject{ |x| /^\./ =~ x }
      these
    end

    def get_patch_object patch, args
      require 'nandoc/patch/support.rb'
      patch = NanDoc::Patch.new(patch_path+"/#{patch}")
      pp = patch.subpatches
      if args.empty?
        out.puts "available gem patches: "<<oxford_comma(pp,' or ',&quoted)
        out.puts command_coda
        return nil
      end
      use_sub = find_one(args.shift, pp)
      patch.gem_patch_name = use_sub
      patch
    end

    def list_patches
      out.puts get_patches.join("\n")
      0
    end

    def patch_path
      NanDoc::Config::patch_path
    end
  end
end
