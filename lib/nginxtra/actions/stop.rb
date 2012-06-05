module Nginxtra
  module Actions
    # The Nginxtra::Actions::Stop class encapsulates stopping nginx.
    class Stop
      include Nginxtra::Action

      # Stop nginx and note the new last stop time.
      def stop
        return no_need_to_stop unless should_stop?
        stop_nginx
        update_last_stop
      end

      def no_need_to_stop
        @thor.say "nginx is already stopped"
      end

      def should_stop?
        return true if force?
        Nginxtra::Config.nginx_running?
      end

      def stop_nginx
        daemon :stop
      end

      def update_last_stop
        Nginxtra::Status[:last_stop_time] = Time.now
      end
    end
  end
end
