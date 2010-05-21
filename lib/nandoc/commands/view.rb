module NanDoc::Commands
  class View < ::Nanoc3::CLI::Commands::View
    def short_desc
      spr = super
      "#{NanDoc::Config.option_prefix}#{spr} (plus blah blah)"
    end

    def run opts, args
      require 'nandoc/patch'
      patch = NanDoc::Patch.load(NanDoc::Config.patch_path+'/view-xml-indexes')
      patch.apply_all
      super
    end
  end
end
