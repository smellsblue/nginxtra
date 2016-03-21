module Nginxtra
  module Actions
    module Rails
      class Server
        include Nginxtra::Action

        def server
          ensure_in_rails_app
          ensure_server_gem_installed

          begin
            start_verbose_output
            start_nginxtra
            wait_till_finished
          ensure
            stop_verbose_output
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
          environment = @thor.options["environment"]
          @thor.empty_directory "tmp" unless File.directory? "tmp"
          @thor.empty_directory "tmp/nginxtra" unless File.directory? "tmp/nginxtra"
          @thor.create_file config_path, %(nginxtra.simple_config do
  rails :port => #{port}, :environment => "#{environment}"
end
), force: true
          @thor.invoke Nginxtra::CLI, ["start"], :basedir => basedir, :config => config_path, :workingdir => workingdir, :"non-interactive" => true
          @thor.say "Listening on http://localhost:#{port}/"
          @thor.say "Environment: #{environment}"
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
          return true if File.exist? "script/rails"
          File.exist?("script/server") && File.exist?("app")
        end

        def start_verbose_output
          return unless @thor.options["verbose"]
          @verbose_run = true
          Thread.new { verbose_thread }
        end

        def stop_verbose_output
          return unless @thor.options["verbose"]
          @verbose_run = false
        end

        def verbose_thread
          environment = @thor.options["environment"]
          log_path = "log/#{environment}.log"

          if File.exist? log_path
            log = File.open log_path, "r"
            log.seek 0, IO::SEEK_END
          else
            while @verbose_run
              if File.exist? log_path
                log = File.open log_path, "r"
                break
              end

              sleep 0.1
            end
          end

          while @verbose_run
            select [log]
            line = log.gets

            if line
              puts line
              puts line while (line = log.gets)
            end

            sleep 0.1
          end
        ensure
          log.close if log
        end
      end
    end
  end
end
