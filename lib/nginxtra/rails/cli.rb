require "thor"

module Nginxtra
  module Rails
    class CLI < Thor
      class_option "trace", :type => :boolean, :banner => "Output stack traces on error"

      desc "server", "Start rails using nginxtra"
      def server
        Nginxtra::Error.protect self do
          Nginxtra::Actions::Rails::Server.new(self, nil).server
        end
      end

      default_task :server
    end
  end
end
