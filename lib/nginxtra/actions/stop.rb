module Nginxtra
  module Actions
    # The Nginxtra::Actions::Stop class encapsulates stopping nginx.
    class Stop
      include Nginxtra::Action

      # Stop nginx and note the new last stop time.
      def stop
        daemon :stop
        Nginxtra::Status[:last_stop_time] = Time.now
      end
    end
  end
end
