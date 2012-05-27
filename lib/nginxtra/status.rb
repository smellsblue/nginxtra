require "yaml"

module Nginxtra
  # The status class encapsulates current state of nginxtra, such as
  # when the last time nginx was compiled and with what options.
  class Status
    @@status = nil
    FILENAME = ".nginxtra_status".freeze

    class << self
      def[](option)
        load!
        @@status[option]
      end

      def[]=(option, value)
        load!
        @@status[option] = value
        save!
        value
      end

      def load!
        return if @@status

        if File.exists? File.join(Nginxtra::Config.base_dir, FILENAME)
          # TODO
        else
          @@status = {}
        end
      end

      private
      def save!
        YAML.dump @@status
      end
    end
  end
end
