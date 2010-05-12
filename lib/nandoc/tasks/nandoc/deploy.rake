namespace :nandoc do
  namespace :deploy do
    prefix = ::NanDoc::Tasks::Prefix
    desc "#{prefix} Upload the compiled site using rsync, shows command"
    task :rsync do
      require 'nandoc/deployers/rsync'

      dry_run     = !!ENV['dry_run']
      config_name = ENV['config'] || :default

      deployer = NanDoc::Deployers::Rsync.new

      deployer.run(:config_name => config_name, :dry_run => dry_run)
    end
  end
end
