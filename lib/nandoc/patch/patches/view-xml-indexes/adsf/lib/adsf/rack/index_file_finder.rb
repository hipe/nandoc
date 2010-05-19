module Adsf::Rack

  class IndexFileFinder

    def initialize(app, options)
      @app  = app
      @root = options[:root] or raise ArgumentError, ':root option is required but was not given'
      @index_filenames = options[:index_filenames] || ['index.html']
    end

    def call(env)
      # Get path
      path_info = ::Rack::Utils.unescape(env['PATH_INFO'])
      path = ::File.join(@root, path_info)

      # Redirect if necessary
      if ::File.directory?(path) && path_info !~ /\/$/
        new_path_info = path_info + '/'
        return [
          302,
          { 'Location' => new_path_info, 'Content-Type' => 'text/html' },
          [ "Redirecting you to #{new_path_info}&hellip;" ]
        ]
      end

      # Add index file if necessary
      new_env = env.dup
      if ::File.directory?(path)
        if index_file_basename = find_index_file(path)
          new_env['PATH_INFO'] = ::File.join(path_info, index_file_basename)
        end
      end

      # Pass on
      @app.call(new_env)
    end

    def find_index_file dir_path
      found = @index_filenames.detect do |basename|
        path_to_index = ::File.join(dir_path, basename)
        ::File.file?(path_to_index)
      end
      found
    end

  end

end
