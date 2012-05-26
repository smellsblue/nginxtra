module Nginxtra
  # A class with some utility methods for nginxtra.
  class Util
    # The name of the nginxtra config file.
    CONFIG_FILE = "nginxtra.conf.rb"

    class << self
      # Obtain the config file path based on the current directory.
      # This will be the path to the first nginxtra.conf.rb found
      # starting at the current directory and working up until it is
      # found or the filesystem boundary is hit (so /nginxtra.conf.rb
      # is the last possible tested file).  If none is found, nil is
      # returned.
      def config_file_path
        path = File.absolute_path "."

        begin
          config = File.join path, CONFIG_FILE
          return config if File.exists? config
          path = File.dirname path
        end until path == "/"

        config = File.join path, CONFIG_FILE
        config if File.exists? config
      end
    end
  end
end
