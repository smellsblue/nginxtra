module Nginxtra
  module Actions
    # The Nginxtra::Actions::Compile class encapsulates compiling
    # nginx so it is ready with the specified compile options.  An
    # optional option of :force can be passed with true to make
    # compilation happen no matter what.
    class Compile
      include Nginxtra::Action

      # Run the full compilation of nginx.
      def compile
        return up_to_date unless should_compile?
        copy_to_base
        configure
        make
        make "install"
        update_last_compile
      end

      # Copy the nginx source directory to the base directory.
      def copy_to_base
        @thor.directory "src/nginx", Nginxtra::Config.src_dir
      end

      # Configure nginx with the specified compile options.
      def configure
        @thor.inside Nginxtra::Config.src_dir do
          @thor.run "sh configure --prefix=#{Nginxtra::Config.build_dir} --conf-path=#{Nginxtra::Config.nginx_config} --pid-path=#{Nginxtra::Config.nginx_pidfile} #{@config.compile_options}"
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
        return true if force?
        Nginxtra::Status[:last_compile_options] != @config.compile_options
      end

      # Update Nginxtra::Status with the last compile time and
      # options.
      def update_last_compile
        Nginxtra::Status[:last_compile_options] = @config.compile_options
        Nginxtra::Status[:last_compile_time] = Time.now
      end

      # Notify the user that the compilation is up to date
      def up_to_date
        @thor.say "nginx compilation is up to date"
      end
    end
  end
end
