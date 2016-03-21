module Nginxtra
  module Error
    # Base error with all the base functionality.
    class Base < StandardError
      def initialize(message, options = nil)
        @options = options
        super(message)
      end

      def output(thor)
        options = @options || { header: message }
        Nginxtra::Error.print_error thor, options
      end
    end

    # Raised if config conversion fails.
    class ConvertFailed < Nginxtra::Error::Base; end

    # Raised when something is in an illegal state, such as when
    # running nginxtra_rails from a directory other than a rails root
    # directory.
    class IllegalState < Nginxtra::Error::Base; end

    # Raised when an invalid configuration is specified, such as the
    # --prefix compile option.
    class InvalidConfig < Nginxtra::Error::Base; end

    # Subclass of InvalidConfig that indicates an option was provided
    # that is not allowed.
    class InvalidCompilationOption < Nginxtra::Error::InvalidConfig
      MESSAGES = {
        "prefix" => "The --prefix compile option is not allowed with nginxtra.  It is reserved so nginxtra can control where nginx is compiled and run from.",
        "sbin-path" => "The --sbin-path compile option is not allowed with nginxtra.  It is reserved so nginxtra can control what binary is used to run nginx.",
        "conf-path" => "The --conf-path compile option is not allowed with nginxtra.  It is reserved so nginxtra can control the configuration entirely via #{Nginxtra::Config::FILENAME}.",
        "pid-path" => "The --pid-path compile option is not allowed with nginxtra.  It is reserved so nginxtra can control where the pid file is created."
      }.freeze

      def initialize(parameter)
        super("Invalid compilation option --#{parameter}", header: "Invalid compilation option --#{parameter}", message: MESSAGES[parameter])
      end
    end

    # Raised when the nginxtra config is missing
    class MissingNginxConfig < Nginxtra::Error::InvalidConfig
      HEADER = "Missing definition for nginx.conf!".freeze
      MESSAGE = "You must define your nginx.conf configuration in your nginxtra.conf.rb file.".freeze

      def initialize
        super("Missing definition for nginx.conf", header: HEADER, message: MESSAGE)
      end
    end

    # Raised if a partial is called with anything but no arguments or
    # a single Hash.
    class InvalidPartialArguments < Nginxtra::Error::InvalidConfig
      HEADER = "Invalid partial arguments!".freeze
      MESSAGE = "You can only pass 0 arguments or 1 hash to a partial!".freeze

      def initialize
        super("Invalid partial arguments", header: HEADER, message: MESSAGE)
      end
    end

    # Raised if you reference passenger without the passenger gem.
    class MissingPassengerGem < Nginxtra::Error::InvalidConfig
      HEADER = "Missing passenger gem!".freeze
      MESSAGE = "You cannot reference passenger unless the passenger gem is installed!".freeze

      def initialize
        super("Missing passenger gem", header: HEADER, message: MESSAGE)
      end
    end

    # Raise when a config file doesn't actually specify the config
    class NoConfigSpecified < Nginxtra::Error::InvalidConfig
      def initialize(config_path)
        super("No configuration is specified in #{config_path}!")
      end
    end

    # Raised when the config file cannot be found.
    class MissingConfig < Nginxtra::Error::Base; end

    # Raised when installing and nginx is detected to be installed.
    class NginxDetected < Nginxtra::Error::Base; end

    # Raised when a run command fails.
    class RunFailed < Nginxtra::Error::Base; end

    class << self
      def print_error(thor, options)
        text = "" << thor.set_color(options[:header], :red, true)
        text << "\n\n" << thor.set_color(options[:message], :red, false) if options[:message]
        thor.print_wrapped text
      end

      def protect(thor)
        yield
      rescue Nginxtra::Error::Base => e
        e.output thor
        raise if thor.options["trace"]
      rescue
        print_error thor, header: "An unexpected error occurred!"
        raise if thor.options["trace"]
      end
    end
  end
end
