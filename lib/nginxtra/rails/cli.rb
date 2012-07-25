require "thor"

module Nginxtra
  module Rails
    class CLI < Thor
      desc "start", "Start rails using nginxtra"
      def start
        say "Not yet implemented..."
      end

      default_task :start
    end
  end
end
