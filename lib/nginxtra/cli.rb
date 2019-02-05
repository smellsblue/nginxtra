require "thor"

module Nginxtra
  class CLI < Thor
    include Thor::Actions

    class_option "force", type: :boolean, banner: "Force a task to happen, regardless of what nginxtra thinks", aliases: "-f"
    class_option "trace", type: :boolean, banner: "Output stack traces on error"
    class_option "non-interactive", type: :boolean, banner: "If nginxtra would ask a question, it instead proceeds as if 'no' were the answer", aliases: "-I"
    class_option "ignore-nginx-check", type: :boolean, banner: "Ignore the nginx check if installing"
    class_option "config", type: :string, banner: "Specify the configuration file to use", aliases: "-c"
    class_option "basedir", type: :string, banner: "Specify the directory to store nginx files", aliases: "-b"
    class_option "workingdir", type: :string, banner: "Specify the working directory", aliases: "-w"

    map "-v" => "version"

    desc "convert", "Convert an nginx.conf file to an nginxtra.conf.rb"
    long_desc "
      Parse nginx.conf and convert it to an equivalent nginxtra.conf.rb file.  Expects
      nginx.conf to be in the current folder, but a different file can be specified
      with the --nginx-conf option.  Parses the compile time options using the nginx
      binary parsed from /etc/init.d/nginx, which can be overridden with the
      --nginx-bin option.  This task will fail if the binary cannot be determined,
      unless the --ignore-nginx-bin option is used, which will cause the compile time
      options to be ignored (and the defaults will be used in the resulting
      nginxtra.conf.rb).  The result will be output to nginxtra.conf.rb in the current
      directory, unless an override value is specified with the --config option."
    method_option "nginx-bin", type: :string, banner: "Point to the compiled nginx to retrieve compile options", aliases: "-n"
    method_option "nginx-conf", type: :string, banner: "Point to the nginx.conf file to retrieve the existing configuration", aliases: "-F", default: "nginx.conf"
    method_option "ignore-nginx-bin", type: :boolean, banner: "Ignore the nginx binary, and assume default compile time options", aliases: "-N"
    method_option "output", type: :boolean, banner: "Output to standard out instead of to a file", aliases: "-o"
    method_option "input", type: :boolean, banner: "Read nginx.conf from standard in instead of a file", aliases: "-i"
    def convert
      Nginxtra::Error.protect self do
        Nginxtra::Actions::Convert.new(self, nil).convert
      end
    end

    desc "print", "Output nginxtra.conf.rb as it is processed as nginx.conf"
    long_desc "
      Output the contents of nginx.conf, as it is defined in nginxtra.conf.rb.  If the
      --file is provided, something other than nginx.conf can be output.  The --list
      option can be provided to list known config files.  The --compile-options option
      can be provided to list compile time options being passed to nginx."
    method_option "compile-options", type: :boolean, banner: "Show compile options being used", aliases: "-C"
    method_option "file", type: :string, banner: "The config file that is printed", aliases: "-F", default: "nginx.conf"
    method_option "list", type: :boolean, banner: "List known files", aliases: "-l"
    def print
      Nginxtra::Error.protect self do
        set_working_dir!
        Nginxtra::Actions::Print.new(self, prepare_config!).print
      end
    end

    desc "compile", "Compiles nginx based on nginxtra.conf.rb"
    long_desc "
      Compile nginx with the compilation options specified in nginxtra.conf.rb.  If it
      has already been compiled with those options, compilation will be skipped.  Note
      that start will already run compilation, so compilation is not really needed to
      be executed directly.  However, you can force recompilation by running this task
      with the --force option."
    def compile
      Nginxtra::Error.protect self do
        set_working_dir!
        Nginxtra::Actions::Compile.new(self, prepare_config!).compile
      end
    end

    desc "install", "Installs nginxtra"
    long_desc "
      Install nginxtra so nginx will start at system startup time, and stop when the
      system is shut down.  Before installing, it will be checked if it had been
      already installed with this version of nginxtra.  If it was already installed,
      installation will be skipped unless the --force option is given."
    def install
      Nginxtra::Error.protect self do
        Nginxtra::Actions::Install.new(self, prepare_config!).install
      end
    end

    desc "start", "Start nginx with configuration defined in nginxtra.conf.rb"
    long_desc "
      Start nginx based on nginxtra.conf.rb.  If nginx has not yet been compiled for
      the given compilation options or the current nginx version, it will be compiled.
      The configuration for nginx will automatically be handled by nginxtra so it
      matches what is defined in nginxtra.conf.rb.  If it is already running, this
      will do nothing, unless --force is passed.  Note that compilation will NOT be
      forced with the --force option and should be invoked separately if it needs to
      be forced.  The --no-daemon option can be used if you want to run without
      start-stop-daemon, though be aware this might break other nginxtra actions like
      stop, restart, and reload.  The process will be replaced with nginx when
      --no-daemon is used."
    method_option "daemon", type: :boolean, default: true, banner: "Start with start-stop-daemon", aliases: "-d"
    def start
      Nginxtra::Error.protect self do
        set_working_dir!
        Nginxtra::Actions::Start.new(self, prepare_config!).start
      end
    end

    desc "stop", "Stop nginx"
    long_desc "
      Stop nginx, unless it is already running based on the pidfile.  If it is
      determined to be running, this command will do nothing, unless --force is passed
      (which will cause it to run the stop command regardless of the pidfile)."
    def stop
      Nginxtra::Error.protect self do
        set_working_dir!
        Nginxtra::Actions::Stop.new(self, prepare_config!).stop
      end
    end

    desc "restart", "Restart nginx"
    def restart
      Nginxtra::Error.protect self do
        set_working_dir!
        Nginxtra::Actions::Restart.new(self, prepare_config!).restart
      end
    end
    map "force-reload" => "restart"

    desc "reload", "Reload nginx"
    def reload
      Nginxtra::Error.protect self do
        set_working_dir!
        Nginxtra::Actions::Reload.new(self, prepare_config!).reload
      end
    end

    desc "status", "Check if nginx is running"
    def status
      Nginxtra::Error.protect self do
        set_working_dir!
        Nginxtra::Actions::Status.new(self, prepare_config!).status
      end
    end

    desc "version", "Show the nginxtra version"
    long_desc "
      This can be optionally used as 'nginxtra -v'"
    def version
      Nginxtra::Error.protect self do
        say Nginxtra::Version
      end
    end

    private

    def prepare_config!
      Nginxtra::Config.base_dir = options["basedir"]
      result = Nginxtra::Config.require! options["config"]
      say "Using config #{Nginxtra::Config.loaded_config_path}"
      result
    end

    def set_working_dir!
      Dir.chdir options["workingdir"] if options["workingdir"]
    end

    class << self
      def source_root
        File.absolute_path File.expand_path("../../..", __FILE__)
      end
    end
  end
end
