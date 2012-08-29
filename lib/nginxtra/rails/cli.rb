require "thor"

module Nginxtra
  module Rails
    class CLI < Thor
      include Thor::Actions

      class_option "trace", :type => :boolean, :banner => "Output stack traces on error"

      map "-v" => "version"

      desc "server", "Start rails using nginxtra"
      method_option "port", :type => :numeric, :banner => "Specify the port to use to run the server on", :aliases => "-p", :default => 3000
      method_option "environment", :banner => "Specify the rails environment to run the server with", :aliases => "-e", :default => "development"
      method_option "verbose", :type => :boolean, :banner => "Attempts to output the log while the server is running", :aliases => "-V"
      def server
        Nginxtra::Error.protect self do
          Nginxtra::Actions::Rails::Server.new(self, nil).server
        end
      end

      desc "version", "Show the nginxtra version"
      long_desc "
        This can be optionally used as 'nginxtra -v'"
      def version
        Nginxtra::Error.protect self do
          say Nginxtra::Version
        end
      end

      default_task :server
    end
  end
end
