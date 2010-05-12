module NanDoc::Erb
  class Agent

    #
    # whatever weird random and fanciful things we want to do with an ERB tree
    #

    class << self
      include NanDoc::OptsNormalizer # unnormalize_opt_keys

      # put parameter values from the command line into the erb files
      # in the task
      #
      # @param [?]
      # @param [Treebis::Task] task - takes erb values
      # @param [Array] names - the list of names it takes
      # @param [Array] argv - ARGV or the like
      #
      def process_erb_values_from_the_commandline cmd, task, names, argv
        @cmd, @task, @names, @argv = cmd, task, names, argv
        @args = nil
        args_none unless argv
        args_parse
        erb_values = args_validate
        task.erb_values(erb_values)
        nil
      end
    private

      def args_none
        err "Please provide args for the erb templates."
        show_usage
        my_exit
      end

      def args_parse
        hash = {}
        @argv.each do |str|
          unless /\A--([-_a-z0-9]*)=(.+)\Z/ =~ str
            err "couldn't parse #{str.inspect} -- expecting \"--foo='bar'\""
            show_usage
            my_exit
          end
          hash[normalize_opt_key($1)] = $2
        end
        @args = hash
      end

      def args_validate
        args = @args.dup
        have = {}
        need = Hash[ @names.map{ |n| [normalize_opt_key(n), true] } ]
        suck = []
        args.each do |k, v|
          if need[k]
            have[k.to_s] = v
            need.delete(k)
          else
            suck.push unnormalize_opt_key(k)
          end
        end
        miss = need.keys.map{ |k| unnormalize_opt_key(k) }
        err "unrecognized erb parameter(s): #{suck.join(' ')}" if suck.any?
        err "missing erb parameter(s): #{miss.join(' ')}" if miss.any?
        if miss.any? or suck.any?
          show_usage;
          my_exit
        end
        have
      end

      def err *a
        $stderr.puts(*a)
      end

      def my_exit
        exit(1)
      end

      def show_usage
        err "usage: nandoc #{@cmd.name} <mysite> -- #{these_things}"
      end

      def these_things
        names = unnormalize_opt_keys(@names)
        vals = ['foo', 'bar', 'bizz bazz']
        vals2 = Array.new(names.size).map{ |x| vals[ rand(vals.size) ] }
        vals3 = names.zip(vals2)
        vals4 = vals3.map{|(name,val)| "#{name}=\"#{val}\"" }
        str = vals4.join(' ')
        str
      end
    end
  end
end
