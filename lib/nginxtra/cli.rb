require "thor"

module Nginxtra
  class CLI < Thor
    include Thor::Actions

    desc "compile", "Compiles nginx based on nginxtra.conf.rb"
    long_desc "
      Compile nginx with the compilation options specified in nginxtra.conf.rb.  If it
      has already been compiled with those options, compilation will be skipped.  Note
      that start will already run compilation, so compilation is not really needed to
      be executed directly.  However, you can force recompilation by running this task
      with the --force option."
    method_option "force", :type => :boolean, :banner => "Force compilation to happen", :aliases => "-f"
    method_option "config", :type => :string, :banner => "Specify the configuration file to use", :aliases => "-c"
    method_option "basedir", :type => :string, :banner => "Specify the directory to store nginx files", :aliases => "-b"
    def compile
      Nginxtra::Actions::Compile.new(self, prepare_config!).compile
    end

    desc "install", "Installs nginxtra"
    long_desc "
      Install nginxtra so nginx will start at system startup time, and stop when the
      system is shut down.  Before installing, it will be checked if it had been
      already installed with this version of nginxtra.  If it was already installed,
      installation will be skipped unless the --force option is given."
    method_option "force", :type => :boolean, :banner => "Force installation to happen", :aliases => "-f"
    method_option "config", :type => :string, :banner => "Specify the configuration file to use", :aliases => "-c"
    method_option "basedir", :type => :string, :banner => "Specify the directory to store nginx files", :aliases => "-b"
    def install
      Nginxtra::Actions::Install.new(self, prepare_config!).install
    end

    desc "start", "Start nginx with configuration defined in nginxtra.conf.rb"
    long_desc "
      Start nginx based on nginxtra.conf.rb.  If nginx has not yet been compiled, it
      will be compiled.  The configuration for nginx will automatically be handled by
      nginxtra so it matches what is defined in nginxtra.conf.rb."
    method_option "config", :type => :string, :banner => "Specify the configuration file to use", :aliases => "-c"
    method_option "basedir", :type => :string, :banner => "Specify the directory to store nginx files", :aliases => "-b"
    def start
      Nginxtra::Actions::Start.new(self, prepare_config!).start
    end

    desc "stop", "Stop nginx"
    method_option "config", :type => :string, :banner => "Specify the configuration file to use", :aliases => "-c"
    method_option "basedir", :type => :string, :banner => "Specify the directory to store nginx files", :aliases => "-b"
    def stop
      Nginxtra::Actions::Stop.new(self, prepare_config!).stop
    end

    desc "restart", "Restart nginx"
    method_option "config", :type => :string, :banner => "Specify the configuration file to use", :aliases => "-c"
    method_option "basedir", :type => :string, :banner => "Specify the directory to store nginx files", :aliases => "-b"
    def restart
      Nginxtra::Actions::Restart.new(self, prepare_config!).restart
    end
    map "force-reload" => "restart"

    desc "reload", "Reload nginx"
    method_option "config", :type => :string, :banner => "Specify the configuration file to use", :aliases => "-c"
    method_option "basedir", :type => :string, :banner => "Specify the directory to store nginx files", :aliases => "-b"
    def reload
      Nginxtra::Actions::Reload.new(self, prepare_config!).reload
    end

    private
    def prepare_config!
      Nginxtra::Config.base_dir = options["basedir"]
      Nginxtra::Config.require! options["config"]
    end

    class << self
      def source_root
        File.absolute_path File.expand_path("../../..", __FILE__)
      end
    end
  end
end
