module Nginxtra
  module Actions
    # The Nginxtra::Actions::Compile class encapsulates compiling
    # nginx so it is ready with the specified compile options.
    class Compile
      def initialize(thor, config)
        @thor = thor
        @config = config
      end

      # Run the full compilation of nginx.
      def compile
        return unless should_compile?
        configure
        make
        make "install"
        update_last_compile!
      end

      # Configure nginx with the specified compile options.
      def configure
        @thor.inside Nginxtra::Config.src_dir do
          @thor.run "./configure --prefix=#{Nginxtra::Config.build_dir} #{@config.compile_options}"
        end
      end

      # Run make against the configured nginx.
      def make(*args)
        @thor.inside Nginxtra::Config.src_dir do
          @thor.run ["make", *args].join(" ")
        end
      end

      # Determine if compiling should happen.  This will return false
      # if the last compile options equal the current options, or if
      # the force option was passed in at construction time.
      def should_compile?
        Nginxtra::Status[:last_compile_options] != @config.compile_options
      end

      # Update Nginxtra::Status with the last compile time and
      # options.
      def update_last_compile!
        Nginxtra::Status[:last_compile_options] = @config.compile_options
        Nginxtra::Status[:last_compile_time] = Time.now
      end
    end
  end
end
