module NanDoc
  module Cli
    module CommandMethods
      # @depends none

      def command_name
        (/::([_a-z0-9]+)\Z/i =~ self.class.to_s and base = $1) or fail('no')
        base.gsub(/([a-z])([A-Z])/){ "#{$1}-#{$2}" }.downcase
      end
      def invite_to_more_command_help
        "see `nandoc help #{command_name}` for more information."
      end
      def command_path_assert name, *paths
        paths.each do |p|
          unless File.exist?(p)
            command_abort("#{name} does not exist: #{p}")
          end
        end
      end
      def invocation_name
        File.basename($PROGRAM_NAME)
      end
      def command_abort msg=nil
        if msg.nil?
          tail = 'Aborting.'
        elsif msg.index("for more info") # not mr. right, mr. right now
          tail = ''
        else
          last = msg[-1].chr
          tail = ".?!".index(last) ? '  ' : ("\n"==last ? '' : '.  ')
          tail << 'Aborting.'
        end
        $stderr.puts "nanDoc: #{msg}#{tail}"
        exit 1
      end
    end
  end
end
