module Nginxtra
  module Error
    # Base error with all the base functionality.
    class Base < StandardError
      def initialize(message, options = nil)
        @options = options
        super(message)
      end

      def output(thor)
        options = @options || { :header => message }
        Nginxtra::Error.print_error thor, options
      end
    end

    # Raised if config conversion fails
    class ConvertFailed < Nginxtra::Error::Base; end

    # Raised when an invalid configuration is specified, such as the
    # --prefix compile option.
    class InvalidConfig < Nginxtra::Error::Base; end

    # Raised when the config file cannot be found.
    class MissingConfig < Nginxtra::Error::Base; end

    # Raised when installing and nginx is detected to be installed.
    class NginxDetected < Nginxtra::Error::Base; end

    # Raised when a run command fails
    class RunFailed < Nginxtra::Error::Base; end

    class << self
      def print_error(thor, options)
        text = "" << thor.set_color(options[:header], :red, true)
        text << "\n\n" << thor.set_color(options[:message], :red, false) if options[:message]
        thor.print_wrapped text
      end

      def protect(thor)
        begin
          yield
        rescue Nginxtra::Error::Base => e
          e.output thor
          raise if thor.options["trace"]
        rescue => e
          print_error thor, :header => "An unexpected error occurred!"
          raise if thor.options["trace"]
        end
      end
    end
  end
end
