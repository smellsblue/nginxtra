require "thor"

module Nginxtra
  class CLI < Thor
    include Thor::Actions
    desc "compile", "Compiles nginx based on nginxtra.conf.rb"
    long_desc "
      Compile nginxt with the compilation options specified in nginxtra.conf.rb.  If it
      has already been compiled with those options, compilation will be skipped.  Note
      that start will already run compilation, so compilation is not really needed to
      be executed directly.  However, you can force recompilation by running this task
      with the --force option."
    method_option "force", :type => :boolean, :banner => "Force compilation to happen", :aliases => "-f"
    method_option "config", :type => :string, :banner => "Specify the configuration file to use", :aliases => "-c"
    def compile
      Nginxtra::Actions::Compile.new(self, require_config!, :force => options["force"]).compile
    end

    desc "start", "Start nginx with configuration defined in nginxtra.conf.rb"
    long_desc "
      Start nginx based on nginxtra.conf.rb.  If nginx has not yet been compiled, it
      will be compiled.  The configuration for nginx will automatically be handled by
      nginxtra so it matches what is defined in nginxtra.conf.rb."
    method_option "config", :type => :string, :banner => "Specify the configuration file to use", :aliases => "-c"
    def start
      Nginxtra::Actions::Start.new(self, require_config!).start
    end

    desc "stop", "Stop nginx"
    method_option "config", :type => :string, :banner => "Specify the configuration file to use", :aliases => "-c"
    def stop
      Nginxtra::Actions::Stop.new(self, require_config!).stop
    end

    desc "restart", "Restart nginx"
    method_option "config", :type => :string, :banner => "Specify the configuration file to use", :aliases => "-c"
    def restart
      Nginxtra::Actions::Restart.new(self, require_config!).restart
    end

    desc "reload", "Reload nginx"
    method_option "config", :type => :string, :banner => "Specify the configuration file to use", :aliases => "-c"
    def reload
      Nginxtra::Actions::Reload.new(self, require_config!).reload
    end

    private
    def require_config!
      Nginxtra::Config.require! options["config"]
    end
  end
end
