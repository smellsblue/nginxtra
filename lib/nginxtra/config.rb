module Nginxtra
  # The Nginxtra::Config class is the central class for configuring
  # nginxtra.  It provides the DSL for defining the compilation
  # options of nginx and the config file contents.
  class Config
    FILENAME = "nginxtra.conf.rb".freeze
    NGINX_CONF_FILENAME = "nginx.conf".freeze
    NGINX_PIDFILE_FILENAME = ".nginx_pid".freeze

    def initialize(*_args)
      @requires_root = false
      @compile_options = []
      @partial_paths = []
      @file_paths = []
      @files = {}
      Nginxtra::Config.last_config = self

      yield self if block_given?
    end

    # Define an additional directory where partials can be found.  The
    # passed in path should have directories listed by configuration
    # file, then partials within those.
    #
    # For example:
    # custom_partials "/my/path"
    #   /my/path/nginx.conf/rails.rb
    #   /my/path/nginx.conf/static.rb
    def custom_partials(path)
      @partial_paths << path
    end

    # Define an additional directory where file templates can be
    # found.  The passed in path should have file templates within it.
    #
    # For example:
    # custom_files "/my/path"
    #   /my/path/nginx.conf.rb
    def custom_files(path)
      @file_paths << path
    end

    # Retrieve an array of directories where partials can be
    # contained.  This includes the custom partial directories added
    # with the "custom_partials" method, in the order they were added,
    # then the standard override location, and finally the standard
    # gem partials.
    def partial_paths
      [].tap do |result|
        result.push(*@partial_paths)
        result.push File.join(Nginxtra::Config.template_dir, "partials")
        result.push File.join(Nginxtra::Config.gem_template_dir, "partials")
      end
    end

    # Retrieve an array of directories where file templates can be
    # contained.  This includes the custom file directories added with
    # the "custom_files" method, in the order they were added, then
    # the standard override location, and finally the standard gem
    # file templates.
    def file_paths
      [].tap do |result|
        result.push(*@file_paths)
        result.push File.join(Nginxtra::Config.template_dir, "files")
        result.push File.join(Nginxtra::Config.gem_template_dir, "files")
      end
    end

    # This method is used to configure nginx via nginxtra.  Inside
    # your nginxtra.conf.rb config file, you should use it like:
    #   nginxtra.config do
    #     ...
    #   end
    def config(&block)
      instance_eval(&block)
      self
    end

    # Support simple configuration in a special block.  This will
    # allow wholesale configuration like for rails.  It supports the
    # :worker_processes and :worker_connections options, which will
    # affect the resulting configuration.
    def simple_config(options = {}, &block)
      SimpleConfig.new(self, options, &block).process!
      self
    end

    # Notify nginxtra that root access is needed to run the daemon
    # commands.  Sudo will automatically be used if the current user
    # isn't root.
    def require_root!
      @requires_root = true
    end

    # Retrieve whether root is required to run the daemon.  This will
    # return true only if require_root! was invoked from the config
    # file.
    def require_root?
      @requires_root
    end

    # Require passenger.  This will include http_gzip_static_module,
    # add a Wno-error compilation option, and add the passenger module
    # to the proper passenger path.
    def require_passenger!
      compile_option %(--with-http_gzip_static_module)
      compile_option %(--with-cc-opt=-Wno-error)
      compile_option %(--add-module="#{Nginxtra::Config.passenger_config_dir}")
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
      raise Nginxtra::Error::InvalidCompilationOption, "prefix" if opt =~ /--prefix=/
      raise Nginxtra::Error::InvalidCompilationOption, "sbin-path" if opt =~ /--sbin-path=/
      raise Nginxtra::Error::InvalidCompilationOption, "conf-path" if opt =~ /--conf-path=/
      raise Nginxtra::Error::InvalidCompilationOption, "pid-path" if opt =~ /--pid-path=/
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
      @files[filename] = Nginxtra::Config::ConfigFile.new filename, self, &block
    end

    # Retrieve the files that have been defined.
    def files
      @files.keys
    end

    class << self
      attr_accessor :last_config

      # Obtain the config file path based on the current directory.
      # This will be the path to the first nginxtra.conf.rb found
      # starting at the current directory and working up until it is
      # found or the filesystem boundary is hit (so /nginxtra.conf.rb
      # is the last possible tested file).  If none is found, nil is
      # returned.
      def path
        path = File.absolute_path "."
        config = File.join path, FILENAME
        return config if File.exist? config
        config = File.join path, "config", FILENAME
        return config if File.exist? config
        path = File.dirname path

        loop do
          config = File.join path, FILENAME
          return config if File.exist? config
          path = File.dirname path
          break if path == "/"
        end

        config = File.join path, FILENAME
        config if File.exist? config
      end

      # Retrieve the path to the config file that was loaded.
      attr_reader :loaded_config_path

      # Determine where the config file is and require it.  Return the
      # resulting config loaded by the path.
      # Nginxtra::Error::MissingConfig will be raised if the config
      # file cannot be found.
      def require!(config_path = nil)
        config_path = if config_path
                        File.absolute_path config_path
                      else
                        path
                      end

        raise Nginxtra::Error::MissingConfig, "Cannot find #{FILENAME} to configure nginxtra!" unless config_path
        raise Nginxtra::Error::MissingConfig, "Missing file #{config_path} to configure nginxtra!" unless File.exist?(config_path)
        require config_path
        raise Nginxtra::Error::NoConfigSpecified, config_path unless last_config
        @loaded_config_path = config_path
        last_config
      end

      # The current version of nginxtra.
      def version
        Nginxtra::Version.to_s
      end

      # The corresponding nginx version (based on the nginxtra
      # version).
      def nginx_version
        @nginx_version ||= version.split(".").take(3).join(".")
      end

      # Retrieve the base dir of nginxtra (located just above lib,
      # probably in your gems/nginxtra-xxx directory).
      def gem_dir
        File.absolute_path File.expand_path("../../..", __FILE__)
      end

      # Set the base directory (retrieved from base_dir).  If this is
      # not called, it will default to the ~/.nginxtra directory.
      # This will do nothing if the value is nil.
      def base_dir=(value)
        @base_dir = value if value
      end

      # Retrieve the base dir of nginxtra stored files (located in
      # ~/.nginxtra, unless overridden via the --basedir option).
      def base_dir
        @base_dir ||= File.absolute_path File.expand_path("~/.nginxtra")
      end

      # The base nginx dir versioned to the current version inside the
      # base dir.
      def base_nginx_dir
        File.join base_dir, "nginx-#{nginx_version}"
      end

      # Retrieve the directory where nginx source is located.
      def src_dir
        File.join base_nginx_dir, "src"
      end

      # Retrieve the directory where nginx is built into.
      def build_dir
        File.join base_nginx_dir, "build"
      end

      # Retrieve the directory where templates are loaded from.
      def template_dir
        File.join base_dir, "templates"
      end

      # Retrieve the directory within the gem where templates are
      # loaded from.
      def gem_template_dir
        File.join gem_dir, "templates"
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

      # Retrieve the path to ruby.
      def ruby_path
        `which ruby`.strip
      end

      # Cache and retrieve the gemspec for passenger, if it exists.
      # An InvalidConfig exception will be raised if passenger cannot
      # be found.
      def passenger_spec
        @passenger_spec ||= Gem::Specification.find_by_name("passenger").tap do |spec|
          raise Nginxtra::Error::MissingPassengerGem if spec.nil?
        end
      end

      def passenger_config_dir
        @passenger_config_dir ||= `#{File.join passenger_spec.bin_dir, "passenger-config"} --nginx-addon-dir`.strip
      end

      # Determine if nginx is running, based on the pidfile.
      def nginx_running?
        return false unless File.exist? nginx_pidfile
        pid = File.read(nginx_pidfile).strip
        Process.getpgid pid.to_i
        true
      rescue Errno::ESRCH
        false
      end
    end

    # Extension point for other gems or libraries that want to define
    # inline partials.  Please see the partial method for usage.
    class Extension
      class << self
        # Determine if there has been a partial defined for the given
        # nginx config file, with the given partial name.
        def partial?(file, name)
          file = file.to_sym
          name = name.to_sym
          @extensions && @extensions[file] && @extensions[file][name]
        end

        # Define or retrieve the partial for the given nginx config
        # file and partial name.  If a block is provided, it is set as
        # the partial, otherwise the partial currently defined for it
        # will be retrieved.  The block is expected to take 2
        # arguments... the arguments hash, and then the block passed
        # in to this definition.  Either may be ignored if so desired.
        #
        # Example usage:
        #   Nginxtra::Config::Extension.partial "nginx.conf", "my_app" do |args, block|
        #     my_app(args[:port] || 80)
        #     some_other_setting "on"
        #     block.call
        #   end
        #
        # The partial will only be valid for the given config file.
        # It is completely nestable, and other partials may be invoked
        # as well.
        def partial(file, name, &block)
          file = file.to_sym
          name = name.to_sym
          @extensions ||= {}
          @extensions[file] ||= {}

          if block
            @extensions[file][name] = block
          else
            @extensions[file][name]
          end
        end

        # Clear all partials so far defined.  This is mainly for test,
        # but could be called if resetting is so desired.
        def clear_partials!
          @extensions = {}
        end
      end
    end

    # Represents a config file being defined by nginxtra.conf.rb.
    class ConfigFile
      def initialize(filename, config, &block)
        @filename = filename
        @config = config
        @indentation = Nginxtra::Config::Indentation.new indent_size: 4
        @file_contents = []
        instance_eval(&block)
      end

      # The file contents that were defined for this config file.
      def config_file_contents
        result = @file_contents.join "\n"
        result += "\n" unless result.empty?
        result
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
        empty_config_line if @end_of_block
        @begin_of_block = false
        @end_of_block = false
        bare_config_line "#{contents};"
      end

      # Add a new line to the config, but without a semicolon at the
      # end.
      #
      # Example usage:
      #   nginxtra.config do
      #     bare_config_line "a line with no semicolon"
      #   end
      def bare_config_line(contents)
        @begin_of_block = false
        @end_of_block = false
        @file_contents << "#{@indentation}#{contents}"
      end

      # Add an empty config line to the resulting config file.
      def empty_config_line
        @begin_of_block = false
        @end_of_block = false
        @file_contents << ""
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
        empty_config_line unless @file_contents.empty? || @begin_of_block
        bare_config_line "#{name} {"
        @begin_of_block = true
        @indentation.increment
        yield if block_given?
        @indentation.decrement
        bare_config_line "}"
        @end_of_block = true
      end

      # Convenience method to use the "break" keyword, as seen in if
      # blocks of nginx configurations.
      def _break(*args, &block)
        process_config_block_or_line "break", args, block
      end

      # Convenience method to invoke an if block in the nginx
      # configuration.  Parenthesis are added around the arguments of
      # this method.
      #
      # Example usage:
      #   nginxtra.config do
      #     _if "some", "~", "thing" do
      #       _return 404
      #     end
      #   end
      #
      # Which will produce the following config:
      #   if (some ~ thing) {
      #     return 404;
      #   }
      def _if(*args, &block)
        config_block "if (#{args.join " "})", &block
      end

      # Convenience method to use the "return" keyword, as seen in if
      # blocks of nginx configurations.
      def _return(*args, &block)
        process_config_block_or_line "return", args, block
      end

      # Process the given template.  Optionally, include options (as
      # yielded values) available to the template.  The yielder passed
      # in will be invoked (if given) if the template invokes yield.
      def process_template!(template, options = {}, yielder = nil)
        if template.respond_to? :call
          block = proc { instance_eval(&yielder) if yielder }
          instance_exec options, block, &template
        else
          process_template_with_yields! template do |x|
            if x
              options[x.to_sym]
            elsif yielder
              instance_eval(&yielder)
            end
          end
        end
      end

      # Helper method for process_template! Which is expected to have
      # a block passed in to handle yields from within the template.
      def process_template_with_yields!(template)
        instance_eval File.read(template)
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
        if partial? method
          invoke_partial method, args, block
        else
          process_config_block_or_line method, args, block
        end
      end

      # Output the passenger_root line, including the proper passenger
      # gem path.
      def passenger_root!
        config_line %(passenger_root #{Nginxtra::Config.passenger_spec.gem_dir})
      end

      # Output the passenger_ruby, including the proper ruby path.
      def passenger_ruby!
        config_line %(passenger_ruby #{Nginxtra::Config.ruby_path})
      end

      # Output that passenger is enabled in this block.
      def passenger_on!
        config_line %(passenger_enabled on)
      end

      private

      def full_partial_paths(partial_name)
        @config.partial_paths.lazy.map do |path|
          File.join path, @filename, "#{partial_name}.rb"
        end
      end

      def partial?(partial_name)
        return true if Nginxtra::Config::Extension.partial? @filename, partial_name

        full_partial_paths(partial_name).any? do |path|
          File.exist? path
        end
      end

      def invoke_partial(partial_name, args, block)
        partial_path = if Nginxtra::Config::Extension.partial? @filename, partial_name
                         Nginxtra::Config::Extension.partial @filename, partial_name
                       else
                         full_partial_paths(partial_name).find do |path|
                           File.exist? path
                         end
                       end

        if args.empty?
          partial_options = {}
        elsif args.length == 1 && args.first.is_a?(Hash)
          partial_options = args.first
        else
          raise Nginxtra::Error::InvalidPartialArguments
        end

        process_template! partial_path, partial_options, block
      end

      def process_config_block_or_line(name, args, block)
        values = [name, *args].join " "

        if block
          config_block values, &block
        else
          config_line values
        end
      end
    end

    # A class for encapsulating simple configuration.
    class SimpleConfig
      def initialize(config, options = {}, &block)
        @config = config
        @options = options
        @block = block
      end

      # Process the simple config.
      def process!
        file_options = @config.file_paths.map do |path|
          find_config_files! path
        end

        config_files = file_options.map(&:keys).inject([], &:+).uniq.map do |x|
          file_options.find do |option|
            option.include? x
          end[x]
        end

        process_files! config_files
      end

      # Find all the config files at the given path directory.  The
      # result will be a hash of hashes.  The key on the outer hash is
      # the output config file name, while the value is a hash of
      # :path to the original file path, and :config_file to the
      # output config file name.
      def find_config_files!(path)
        files_hash = {}

        Dir["#{path}/**/*.rb"].each do |x|
          next unless File.file? x
          file_name = x.sub %r{^#{Regexp.quote path.to_s}/(.*)\.rb$}, "\\1"
          files_hash[file_name] = { path: x, config_file: file_name }
        end

        files_hash
      end

      # Process all config files passed in, where each is a hash with
      # :path to the original path of the file, and :config_file to
      # the output config file name.
      def process_files!(files)
        files.each do |x|
          path = x[:path]
          filename = x[:config_file]
          options = @options
          block = @block

          @config.file filename do
            process_template! path, options, block
          end
        end
      end
    end

    class Indentation
      attr_reader :value

      def initialize(options = {})
        @value = 0
        @options = options
      end

      def indent_size
        @options[:indent_size] || 2
      end

      def done?
        @value == 0
      end

      def decrement
        adjust(-1)
      end

      def increment
        adjust(1)
      end

      def to_s
        " " * indent_size * @value
      end

      private

      def adjust(amount)
        @value += amount
        raise Nginxtra::Error::ConvertFailed, "Missing block end!" if @value < 0
        @value
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
def nginxtra(*args, &block)
  Nginxtra::Config.new(*args, &block)
end
