module Nginxtra
  module Actions
    class Start
      def initialize(thor, config)
        @thor = thor
        @config = config
      end

      def start
        compile
        save_config
        link_config
        start_nginx
        update_last_start
      end

      def compile
        Nginxtra::Actions::Compile.new(@thor, @config).compile
      end

      def save_config
        File.write Nginxtra::Config.nginx_config, @config.config_contents
      end

      def link_config
        @thor.inside File.join(Nginxtra::Config.build_dir, "conf") do
          @thor.create_link "nginx.conf", Nginxtra::Config.nginx_config
        end
      end

      def start_nginx
        @thor.run "start-stop-daemon --start --quiet --pidfile #{Nginxtra::Config.nginx_pidfile} --exec #{Nginxtra::Config.nginx_executable}"
      end

      def update_last_start
        Nginxtra::Status[:last_start_time] = Time.now
      end
    end
  end
end
