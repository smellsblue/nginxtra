require "yaml"

module Nginxtra
  # The status class encapsulates current state of nginxtra, such as
  # when the last time nginx was compiled and with what options.
  class Status
    @@status = nil
    # The name of the file that stores the state.
    FILENAME = ".nginxtra_status".freeze

    class << self
      # Retrieve an option from the state stored in the filesystem.
      # This will first load the state from the .nginxtra_status file
      # in the root of the nginxtra gem directory, if it has not yet
      # been loaded.
      def[](option)
        load!
        @@status[option]
      end

      # Store an option to the status state.  This will save out to
      # the filesystem immediately after storing this option.  The
      # return value will be the value stored to the given option key.
      def[]=(option, value)
        load!
        @@status[option] = value
        save!
        value
      end

      private
      # Load the status state, if it hasn't yet been loaded.  If there
      # is no file yet existing, then the state is simply initialized
      # to an empty hash (and it is NOT stored to the filesystem til
      # the first write).
      def load!
        return if @@status

        if File.exists? path
          @@status = YAML.load File.read path
        else
          @@status = {}
        end
      end

      # The full path to the file with the state.
      def path
        File.join Nginxtra::Config.base_dir, FILENAME
      end

      # Save the current state to disk.
      def save!
        File.write path, YAML.dump(@@status)
      end
    end
  end
end
