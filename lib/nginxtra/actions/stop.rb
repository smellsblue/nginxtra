module Nginxtra
  module Actions
    # The Nginxtra::Actions::Stop class encapsulates stopping nginx.
    class Stop
      include Nginxtra::Action

      # Stop nginx and note the new last stop time.
      def stop
        @thor.run "start-stop-daemon --stop --quiet --pidfile #{Nginxtra::Config.nginx_pidfile} --exec #{Nginxtra::Config.nginx_executable}"
        Nginxtra::Status[:last_stop_time] = Time.now
      end
    end
  end
end
