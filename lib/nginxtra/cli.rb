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
    def compile
      Nginxtra::Actions::Compile.new(self, Nginxtra::Config.require!, :force => options["force"]).compile
    end

    desc "start", "Start nginx with configuration defined in nginxtra.conf.rb"
    long_desc "
      Start nginx based on nginxtra.conf.rb.  If nginx has not yet been compiled, it
      will be compiled.  The configuration for nginx will automatically be handled by
      nginxtra so it matches what is defined in nginxtra.conf.rb."
    def start
      Nginxtra::Actions::Start.new(self, Nginxtra::Config.require!).start
    end

    desc "stop", "Stop nginx"
    def stop
      Nginxtra::Actions::Stop.new(self, Nginxtra::Config.require!).stop
    end

    desc "restart", "Restart nginx"
    def restart
      Nginxtra::Actions::Restart.new(self, Nginxtra::Config.require!).restart
    end

    desc "reload", "Reload nginx"
    def reload
      Nginxtra::Actions::Reload.new(self, Nginxtra::Config.require!).reload
    end
  end
end
