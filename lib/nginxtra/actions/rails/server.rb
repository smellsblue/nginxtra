module Nginxtra
  module Actions
    module Rails
      class Server
        include Nginxtra::Action

        def server
          ensure_in_rails_app
          ensure_server_gem_installed

          begin
            start_nginxtra
            wait_till_finished
          ensure
            stop_nginxtra
          end
        end

        def ensure_in_rails_app
          unless in_rails_app?
            raise Nginxtra::Error::IllegalState.new "You must be in a rails root directory to run nginxtra_rails."
          end
        end

        def ensure_server_gem_installed
          unless passenger_installed?
            raise Nginxtra::Error::IllegalState.new "Please 'gem install passenger' to continue."
          end
        end

        def start_nginxtra
          port = @thor.options["port"]
          @thor.empty_directory "tmp" unless File.directory? "tmp"
          @thor.empty_directory "tmp/nginxtra" unless File.directory? "tmp/nginxtra"
          @thor.create_file config_path, %{nginxtra.simple_config do
  rails :port => #{port}
end
}, :force => true
          @thor.invoke Nginxtra::CLI, ["start"], :basedir => basedir, :config => config_path, :workingdir => workingdir, :"non-interactive" => true
          @thor.say "Listening on http://localhost:#{port}/"
        end

        def wait_till_finished
          @thor.say "Ctrl-C or Ctrl-D to shutdown server"
          next until $stdin.getc.nil?
          @thor.say "Captured Ctrl-D..."
        rescue Interrupt
          @thor.say "Captured Ctrl-C..."
        end

        def stop_nginxtra
          @thor.invoke Nginxtra::CLI, ["stop"], :basedir => basedir, :config => config_path, :workingdir => workingdir, :"non-interactive" => true
        end

        def passenger_installed?
          Gem::Specification.find_by_name("passenger")
        end

        def basedir
          File.absolute_path "tmp/nginxtra"
        end

        def config_path
          File.absolute_path "tmp/nginxtra.conf.rb"
        end

        def workingdir
          File.absolute_path "."
        end

        def in_rails_app?
          return true if File.exists? "script/rails"
          File.exists?("script/server") && File.exists?("app")
        end
      end
    end
  end
end
