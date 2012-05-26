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
        configure
        make
        make "install"
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
    end
  end
end
