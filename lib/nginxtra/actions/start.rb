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
        compile
        save_config_files
        start_nginx
        update_last_start
      end

      # Invoke nginx compilation, to ensure it is up to date.
      def compile
        Nginxtra::Actions::Compile.new(@thor, @config).compile
      end

      # Save nginx config files to the proper config file path.
      def save_config_files
        files = @config.files
        raise Nginxtra::Error::InvalidConfig.new("Missing definition for nginx.conf") unless files.include? "nginx.conf"

        @thor.inside Nginxtra::Config.config_dir do
          files.each do |filename|
            @thor.remove_file filename
            @thor.create_file filename, @config.file_contents(filename)
          end
        end
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
