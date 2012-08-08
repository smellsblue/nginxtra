require "thor"

module Nginxtra
  module Rails
    class CLI < Thor
      include Thor::Actions

      class_option "trace", :type => :boolean, :banner => "Output stack traces on error"

      desc "server", "Start rails using nginxtra"
      method_option "port", :type => :numeric, :banner => "Specify the port to use to run the server on", :aliases => "-p", :default => 3000
      def server
        Nginxtra::Error.protect self do
          Nginxtra::Actions::Rails::Server.new(self, nil).server
        end
      end

      default_task :server
    end
  end
end
