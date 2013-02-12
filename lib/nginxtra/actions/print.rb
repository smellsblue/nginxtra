module Nginxtra
  module Actions
    class Print
      include Nginxtra::Action

      def print
        if @thor.options["list"]
          @thor.say "Known config files:\n  #{@config.files.sort.join "\n  "}"
        elsif @config.files.include?(file)
          @thor.say @config.file_contents(file)
        else
          @thor.say "No config file by the name '#{file}' exists!"
        end
      end

      def file
        @thor.options["file"]
      end
    end
  end
end
