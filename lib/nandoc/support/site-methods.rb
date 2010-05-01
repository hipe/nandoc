module NanDoc
  module SiteMethods

    def deduce_site_path_or_fail args
      if args.any?
        deduce_site_path_from_args args
      else
        deduce_site_path_from_persistent_data
      end
    end

  private

    def config_path_for_site_path path
      path + '/config.yaml'
    end

    def deduce_site_path_from_args args
      if File.exist?(args.first)
        path = args.first
        unless path == persistent_get('last_site_path')
          persistent_set('last_site_path', path)
        end
        path
      else
        task_abort <<-D.gsub(/^  */,'')
          site path not found: #{args.first.inspect}
          usage: #{usage}
          #{invite_to_more_command_help}
        D
      end
    end

    def deduce_site_path_from_persistent_data
      if path = persistent_get('last_site_path')
        if File.exist?(path)
          path
        else
          persistent_set('last_site_path',false)
          task_abort <<-D.gsub(/^  */,'')
          previous site path is stale (#{path.inspect}) and no site provided
          usage: #{usage}
          #{invite_to_more_command_help}
          D
        end
      else
        task_abort(
        'no site path provided and no site path in persistent data file '<<
        "(#{NanDoc.dotfile_path})\n"<<
        <<-D.gsub(/^ */,'')
        usage: #{usage}
        #{invite_to_more_command_help}
        D
        )
      end
    end

    #
    # you just get the raw file data tree, it's not merged in with any
    # DEFAULT_CONFIG stuff or anything
    #
    def parse_config_for_site_path path
      config_path = config_path_for_site_path( path )
      task_abort("config file for app not found: #{config_path}") unless
        File.exist?(config_path)
      YAML.load_file config_path
    end
  end
end
