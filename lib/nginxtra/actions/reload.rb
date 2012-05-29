module Nginxtra
  module Actions
    # The Nginxtra::Actions::Reload class encapsulates reloading nginx.
    class Reload
      include Nginxtra::Action

      # Reload nginx.
      def reload
        daemon :stop, "--signal HUP"
        Nginxtra::Status[:last_reload_time] = Time.now
      end
    end
  end
end
