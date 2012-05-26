module Nginxtra
  # The Nginxtra::Config class is the central class for configuring
  # nginxtra.  It provides the DSL for defining the compilation
  # options of nginx and the config file contents.
  class Config
    def initialize
      @compile_options = []
      @file_contents = []
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
    # --sbin-path and --conf-path.  The order the options are
    # specified will be the order they are used when configuring
    # nginx.
    #
    # Example usage:
    #   nginxtra.config do
    #     option "--with-http_gzip_static_module"
    #     option "--with-cc-opt=-Wno-error"
    #   end
    def option(opt)
      opt = "--#{opt}" unless opt =~ /^--/
      raise Nginxtra::Error::InvalidConfig.new("The --prefix compile option is not allowed with nginxtra.  It is reserved so nginxtra can control where nginx is compiled and run from.") if opt =~ /--prefix=/
      raise Nginxtra::Error::InvalidConfig.new("The --sbin-path compile option is not allowed with nginxtra.  It is reserved so nginxtra can control what binary is used to run nginx.") if opt =~ /--sbin-path=/
      raise Nginxtra::Error::InvalidConfig.new("The --conf-path compile option is not allowed with nginxtra.  It is reserved so nginxtra can control the configuration entirely via #{Nginxtra::Util::CONFIG_FILE}.") if opt =~ /--conf-path=/
      @compile_options << opt
    end

    # Obtain the config file contents that will be used for
    # nginx.conf.
    def config_contents
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

# This is an alias for constructing a new Nginxtra::Config object.  It
# is used for readability of the nginxtra.conf.rb config file.
# Example usage:
#   nginxtra.config do
#     ...
#   end
def nginxtra
  Nginxtra::Config.new
end
