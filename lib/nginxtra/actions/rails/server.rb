module Nginxtra
  module Actions
    module Rails
      class Server
        include Nginxtra::Action

        def server
          ensure_in_rails_app
          start_nginxtra
          wait_till_finished
          stop_nginxtra
        end

        def ensure_in_rails_app
          unless in_rails_app?
            raise Nginxtra::Error::IllegalState.new "You must be in a rails root directory to run nginxtra_rails."
          end
        end

        def start_nginxtra
        end

        def wait_till_finished
          @thor.say "Ctrl-C or Ctrl-D to shutdown server"
          next until $stdin.getc.nil?
          @thor.say "Captured Ctrl-D..."
        rescue Interrupt
          @thor.say "Captured Ctrl-C..."
        end

        def stop_nginxtra
        end

        def in_rails_app?
          return true if File.exists? "script/rails"
          File.exists?("script/server") && File.exists?("app")
        end
      end
    end
  end
end
