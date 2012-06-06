module Nginxtra
  class ConfigConverter
    def initialize(output)
      @converted = false
      @output = output
    end

    def convert(options)
      raise Nginxtra::Error::ConvertFailed.new("The convert method can only be called once!") if converted?
      header
      footer
      converted!
    end

    private
    def header
      @output.puts "nginxtra.config do"
    end

    def footer
      @output.puts "end"
    end

    def converted!
      @converted = true
    end

    def converted?
      @converted
    end
  end
end
