require "stringio"

module Nginxtra
  module Actions
    class Convert
      include Nginxtra::Action

      def convert
        @streams_to_close = []
        converter = Nginxtra::ConfigConverter.new output
        converter.convert :config => config, :binary_status => binary_status
        save_if_necessary!
      ensure
        close_streams!
      end

      private
      def output
        if @thor.options["output"]
          STDOUT
        elsif @thor.options["config"]
          @output = @thor.options["config"]
          @stringio = StringIO.new
        else
          @output = "nginxtra.conf.rb"
          @stringio = StringIO.new
        end
      end

      def save_if_necessary!
        return unless @output && @stringio
        @thor.create_file @output, @stringio.string
      end

      def config
        if @thor.options["input"]
          STDIN
        elsif @thor.options["nginx-conf"]
          open_file @thor.options["nginx-conf"]
        end
      end

      def binary_status
        return if @thor.options["ignore-nginx-bin"]

        if @thor.options["nginx-bin"]
          @thor.run "#{@thor.options["nginx-bin"]} -V 2>&1", :capture => true
        else
          raise "TODO: Figure out the nginx binary location and call -V"
        end
      end

      def open_file(path)
        raise "Missing config file #{path}" unless File.exists? path

        File.open(path, "r").tap do |stream|
          @streams_to_close << stream
        end
      end

      def close_streams!
        @streams_to_close.each &:close
      end
    end
  end
end
