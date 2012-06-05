module Nginxtra
  module Actions
    # The Nginxtra::Actions::Status class encapsulates checking on the
    # status of nginx (whether or not it is running based on the pid
    # file).
    class Status
      include Nginxtra::Action

      def status
        @thor.say "The nginx server status: #{colored_message}"
      end

      def colored_message
        if Nginxtra::Config.nginx_running?
          @thor.set_color "running", :green, true
        else
          @thor.set_color "stopped", :red, true
        end
      end
    end
  end
end
