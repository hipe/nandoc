require 'nandoc/support/string-methods'

module NanDoc
  module Cli
    module CommandMethods
      include NanDoc::StringMethods

      # @depends none
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
        err.puts "nanDoc: #{msg}#{tail}"
        exit 1
      end
      # @return [String] what you would typically say after an error message
      def command_coda
        "usage: #{usage}\n#{invite_to_more_command_help}"
      end
      def command_name
        (/::([_a-z0-9]+)\Z/i =~ self.class.to_s and base = $1) or fail('no')
        base.gsub(/([a-z])([A-Z])/){ "#{$1}-#{$2}" }.downcase
      end
      def command_path_assert name, *paths
        paths.each do |p|
          unless File.exist?(p)
            command_abort("#{name} does not exist: #{p}")
          end
        end
      end
      def disambiguate_item found, items
        err.puts "did you mean "<<oxford_comma(found,' or ',&quoted)
        command_abort(comand_coda)
        nil
      end
      # @return [IO] the stream to write error messages to
      def err
        $stderr
      end
      def find_one item, items
        search = /^#{Regexp.escape(item)}/
        found = items.grep(search)
        use_name = nil
        case found.size
        when 0; return item_not_found(name, items)
        when 1; use_name = found.first
        else; return disambiguate_item(found, items)
        end
        use_name
      end
      def invite_to_more_command_help
        "see `nandoc help #{command_name}` for more information."
      end
      def invocation_name
        File.basename($PROGRAM_NAME)
      end
      def item_not_found name, items
        err.puts "not found: #{name.inspect}"
        err.puts "expecting "<<oxford_comma(items,' or ',&quoted)
        command_abort(command_coda)
        nil
      end
      def out
        $stdout
      end
    end
  end
end
