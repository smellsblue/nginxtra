module Nginxtra
  module Actions
    # The Nginxtra::Actions::Restart class encapsulates restarting nginx.
    class Restart
      include Nginxtra::Action

      # Restart nginx by stopping and starting.
      def restart
        Nginxtra::Actions::Stop.new(@thor, @config).stop
        sleep 1
        Nginxtra::Actions::Start.new(@thor, @config).start
      end
    end
  end
end
