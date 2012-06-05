module Nginxtra
  module Actions
    # The Nginxtra::Actions::Compile class encapsulates starting nginx
    # with the specified configuration file.  It also makes sure that
    # nginx has been compiled with the correct options.
    class Start
      include Nginxtra::Action

      # First, ensure nginx has been compiled, then make sure
      # configuration is correct, and finally start nginx and note the
      # start time.
      def start
        without_force do
          compile
          install
        end

        return no_need_to_start unless should_start?
        save_config_files
        start_nginx
        update_last_start
      end

      # Invoke nginx compilation, to ensure it is up to date.
      def compile
        Nginxtra::Actions::Compile.new(@thor, @config).compile
      end

      # Invoke nginxtra installation, but only if the user allows it.
      def install
        Nginxtra::Actions::Install.new(@thor, @config).optional_install
      end

      # Save nginx config files to the proper config file path.
      def save_config_files
        files = @config.files
        raise Nginxtra::Error::InvalidConfig.new("Missing definition for nginx.conf") unless files.include? "nginx.conf"

        @thor.inside Nginxtra::Config.config_dir do
          files.each do |filename|
            @thor.create_file filename, @config.file_contents(filename), :force => true
          end
        end
      end

      # Notify the user that nginx is already started.
      def no_need_to_start
        @thor.say "nginx is already started"
      end

      # Determine if we should even bother starting.  This returns
      # true if the user forced, or if nginx is already running.
      def should_start?
        return true if force?
        !Nginxtra::Config.nginx_running?
      end

      # Start nginx as a daemon.
      def start_nginx
        daemon :start
      end

      # Update the last nginx start time.
      def update_last_start
        Nginxtra::Status[:last_start_time] = Time.now
      end
    end
  end
end
