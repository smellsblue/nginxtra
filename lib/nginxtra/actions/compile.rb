module Nginxtra
  module Actions
    class Compile
      def initialize(thor, config)
        @thor = thor
        @config = config
      end

      def compile
        configure
      end

      def configure
        @thor.inside Nginxtra::Config.src_dir do
          @thor.run "./configure --prefix=#{Nginxtra::Config.build_dir} #{@config.compile_options}"
        end
      end
    end
  end
end
