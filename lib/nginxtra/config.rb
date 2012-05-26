module Nginxtra
  # The Nginxtra::Config class is the central class for configuring
  # nginxtra.  It provides the DSL for defining the compilation
  # options of nginx and the config file contents.
  class Config
    # The options passed in to the config method.
    attr_reader :options

    DEFAULT_OPTIONS = { :auto_semicolon => true }.freeze

    def initialize
      @options = DEFAULT_OPTIONS.dup
      @compile_options = []
    end

    # This method is used to configure nginx via nginxtra.  Inside
    # your nginxtra.conf.rb config file, you should use it like:
    #   nginxtra.config do
    #     ...
    #   end
    #
    # Some options are permitted:
    # * auto_semicolon: Defaults to true, auto adds ; to config lines.
    #
    # Example usage:
    #   nginxtra.config :auto_semicolon => false do
    #     ...
    #   end
    def config(options = {}, &block)
      @options = DEFAULT_OPTIONS.merge options
      instance_eval &block
      self
    end

    # Obtain the compile_options that have been configured.
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
