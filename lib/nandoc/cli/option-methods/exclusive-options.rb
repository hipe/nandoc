module NanDoc
  module Cli
    class ExclusiveOptions
      include OptionMethods
      def initialize &block
        @exclusive_flag_keys = nil
        @default_short = nil
        @default_key = nil
        @notice_stream = $stderr
        instance_eval(&block)
        fail('definition block needs at least flags()') unless
          @exclusive_flag_keys
      end
      def flags * exclusive_flag_keys
        @exclusive_flag_keys = exclusive_flag_keys
      end
      # params: [short_name_string] name_key
      def default *a
        if a.first.kind_of?(String)
          @default_short = a.shift
        end
        if a.first.kind_of?(Symbol)
          @default_key = a.shift
        else
          fail("bad args: #{a.first.inspect}")
        end
        fail("extra args: #{a.inspect}") if a.any?
      end
      def notice_stream mixed
        @notice_stream = mixed
      end
      def parse cmd, opts
        these = @exclusive_flag_keys & opts.keys
        if these.empty? && @default_key
          if @notice_stream
            msg =
            ["using default: "+unnormalize_opt_key(@default_key),
              @default_short ? "(#{@default_short})" : nil
            ].compact.join(' ')
            @notice_stream.puts msg
          end
          these.push(@default_key)
        end
        if these.size > 1
          flags = unnormalize_opt_keys(@exclusive_flag_keys)
          cmd.command_abort <<-ABORT.gsub(/^  */,'')
            #{flags.join(' and ')} are mutually exclusive.
            usage: #{cmd.usage}
            #{cmd.invite_to_more_command_help}
          ABORT
        end
        these.first
      end
    end
  end
end
