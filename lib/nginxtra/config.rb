module Nginxtra
  # The Nginxtra::Config class is the central class for configuring
  # nginxtra.  It provides the DSL for defining the compilation
  # options of nginx and the config file contents.
  class Config
    FILENAME = "nginxtra.conf.rb".freeze
    NGINX_CONF_FILENAME = "nginx.conf".freeze
    NGINX_PIDFILE_FILENAME = ".nginx_pid".freeze
    @@last_config = nil

    def initialize
      @compile_options = []
      @files = {}
      @@last_config = self
    end

    # This method is used to configure nginx via nginxtra.  Inside
    # your nginxtra.conf.rb config file, you should use it like:
    #   nginxtra.config do
    #     ...
    #   end
    def config(&block)
      instance_eval &block
      self
    end

    # Obtain the compile options that have been configured.
    def compile_options
      @compile_options.join " "
    end

    # Specify a compile time option for nginx.  The leading "--" is
    # optional and will be added if missing.  The following options
    # are not allowed and will cause an exception: --prefix,
    # --sbin-path, --conf-path and --pid-path.  The order the options
    # are specified will be the order they are used when configuring
    # nginx.
    #
    # Example usage:
    #   nginxtra.config do
    #     compile_option "--with-http_gzip_static_module"
    #     compile_option "--with-cc-opt=-Wno-error"
    #   end
    def compile_option(opt)
      opt = "--#{opt}" unless opt =~ /^--/
      raise Nginxtra::Error::InvalidConfig.new("The --prefix compile option is not allowed with nginxtra.  It is reserved so nginxtra can control where nginx is compiled and run from.") if opt =~ /--prefix=/
      raise Nginxtra::Error::InvalidConfig.new("The --sbin-path compile option is not allowed with nginxtra.  It is reserved so nginxtra can control what binary is used to run nginx.") if opt =~ /--sbin-path=/
      raise Nginxtra::Error::InvalidConfig.new("The --conf-path compile option is not allowed with nginxtra.  It is reserved so nginxtra can control the configuration entirely via #{Nginxtra::Config::FILENAME}.") if opt =~ /--conf-path=/
      raise Nginxtra::Error::InvalidConfig.new("The --pid-path compile option is not allowed with nginxtra.  It is reserved so nginxtra can control where the pid file is created.") if opt =~ /--pid-path=/
      @compile_options << opt
    end

    # Obtain the config file contents that will be used for
    # nginx.conf.
    def file_contents(filename)
      @files[filename].config_file_contents
    end

    # Define a new config file with the given filename and the block
    # to define it with.
    def file(filename, &block)
      @files[filename] = Nginxtra::Config::ConfigFile.new(&block)
    end

    # Retrieve the files that have been defined.
    def files
      @files.keys
    end

    class << self
      # Obtain the last Nginxtra::Config object that was created.
      def last_config
        @@last_config
      end

      # Obtain the config file path based on the current directory.
      # This will be the path to the first nginxtra.conf.rb found
      # starting at the current directory and working up until it is
      # found or the filesystem boundary is hit (so /nginxtra.conf.rb
      # is the last possible tested file).  If none is found, nil is
      # returned.
      def path
        path = File.absolute_path "."

        begin
          config = File.join path, FILENAME
          return config if File.exists? config
          path = File.dirname path
        end until path == "/"

        config = File.join path, FILENAME
        config if File.exists? config
      end

      # Determine where the config file is and require it.  Return the
      # resulting config loaded by the path.
      # Nginxtra::Error::MissingConfig will be raised if the config
      # file cannot be found.
      def require!(config_path = nil)
        if config_path
          config_path = File.absolute_path config_path
        else
          config_path = path
        end

        raise Nginxtra::Error::MissingConfig.new("Cannot find #{FILENAME} to configure nginxtra!") unless config_path
        require config_path
        raise Nginxtra::Error::InvalidConfig.new("No configuration is specified in #{config_path}!") unless last_config
        last_config
      end

      # Retrieve the base dir of nginxtra (located just above lib,
      # probably in your gems/nginxtra-xxx directory).
      def base_dir
        File.absolute_path File.expand_path("../../..", __FILE__)
      end

      # Retrieve the directory where nginx source is located.
      def src_dir
        File.join base_dir, "src/nginx"
      end

      # Retrieve the directory where nginx is built into.
      def build_dir
        File.join base_dir, "build/nginx"
      end

      # The path to the config directory where nginx config files are
      # stored (including nginx.conf).
      def config_dir
        File.join base_dir, "conf"
      end

      # The full path to the nginx.conf file that is fed to nginx,
      # based on nginxtra.conf.rb.
      def nginx_config
        File.join config_dir, NGINX_CONF_FILENAME
      end

      # The full path to the nginx pidfile that is used for running
      # nginx.
      def nginx_pidfile
        File.join base_dir, NGINX_PIDFILE_FILENAME
      end

      # Retrieve the full path to the nginx executable.
      def nginx_executable
        File.join build_dir, "sbin/nginx"
      end
    end

    # Represents a config file being defined by nginxtra.conf.rb.
    class ConfigFile
      def initialize(&block)
        @file_contents = []
        instance_eval &block
      end

      # The file contents that were defined for this config file.
      def config_file_contents
        @file_contents.join "\n"
      end

      # Add a new line to the config.  A semicolon is added
      # automatically.
      #
      # Example usage:
      #   nginxtra.config do
      #     config_line "user my_user"
      #     config_line "worker_processes 42"
      #   end
      def config_line(contents)
        @file_contents << "#{contents};"
      end

      # Add a new line to the config, but without a semicolon at the
      # end.
      #
      # Example usage:
      #   nginxtra.config do
      #     bare_config_line "a line with no semicolon"
      #   end
      def bare_config_line(contents)
        @file_contents << contents
      end

      # Add a new block to the config.  This will result in outputting
      # something in the config like a server block, wrapped in { }.  A
      # block should be passed in to this method, which will represent
      # the contents of the block (if no block is given, the resulting
      # config will have an empty block).
      #
      # Example usage:
      #   nginxtra.config do
      #     config_block "events" do
      #       config_line "worker_connections 512"
      #     end
      #   end
      def config_block(name)
        @file_contents << "#{name} {"
        yield if block_given?
        @file_contents << "}"
      end

      # Arbitrary config can be specified as long as the name doesn't
      # clash with one of the Config instance methods.
      #
      # Example usage:
      #   nginxtra.config do
      #     user "my_user"
      #     worker_processes 42
      #     events do
      #       worker_connections 512
      #     end
      #   end
      #
      # Any arguments the the method will be joined with the method name
      # with a space to produce the output.
      def method_missing(method, *args, &block)
        values = [method, *args].join " "

        if block
          config_block values, &block
        else
          config_line values
        end
      end
    end
  end
end

# This is an alias for constructing a new Nginxtra::Config object.  It
# is used for readability of the nginxtra.conf.rb config file.
# Example usage:
#   nginxtra.config do
#     ...
#   end
def nginxtra
  Nginxtra::Config.new
end
