module NanDoc
  module Cli
    module OptionMethods
      #
      # only call this if you are like a ::Cri::Command object with
      # all the nanDoc hacks. ick.  This is a temprary hack.  Trollop et al
      # do this better.
      #
      def exclusive_opt_flags opts, &block
        require File.dirname(__FILE__)+'/option-methods/exclusive-options.rb'
        ExclusiveOptions.new(&block).parse(self, opts)
      end
      def normalize_opts opts
        opts = opts.dup
        opts.keys.select{|x| x.to_s.index('-') }.each do |k|
          opts[normalize_opt_key(k)] = opts.delete(k)
        end
        opts
      end
      def option_enum
        require File.dirname(__FILE__)+'/option-methods/option-enum.rb'
        OptionEnum
      end
      def normalize_opt_key k
        k.to_s.gsub('-','_').to_sym
      end
      def unnormalize_opt_keys keys
        keys.map{|x| unnormalize_opt_key(x)}
      end
      def unnormalize_opt_key key
        "--#{key.to_s.gsub('_','-')}"
      end
    end
  end
end
