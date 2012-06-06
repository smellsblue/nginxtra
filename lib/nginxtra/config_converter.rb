module Nginxtra
  class ConfigConverter
    def initialize(output)
      @converted = false
      @output = output
    end

    def convert(options)
      raise Nginxtra::Error::ConvertFailed.new("The convert method can only be called once!") if converted?
      header
      config_file options[:config]
      footer
      converted!
    end

    private
    def header
      @output.puts "nginxtra.config do"
    end

    def config_file(input)
      tokens = []

      each_token(input) do |token|
        if token.end?
          process_line tokens
          tokens = []
        else
          tokens << token
        end
      end
    end

    def process_line(tokens)
      first = tokens.first
      rest = tokens.drop 1
      @output.print "  "
      @output.print first.value

      if rest.empty?
        @output.puts ""
      else
        @output.print " "
        @output.puts rest.map(&:to_s).join " "
      end
    end

    def each_token(input)
      token = Nginxtra::ConfigConverter::Token.new

      while c = input.read(1)
        if c == "#"
          chomp_comment input
        else
          token << c
        end

        yield token.instance while token.ready?
      end

      yield token.instance while token.ready?
    end

    def chomp_comment(input)
      while c = input.read(1)
        break if c == "\n"
      end
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

    class Token
      TERMINAL_CHARACTERS = ["{", "}", ";"].freeze
      attr_reader :value

      def initialize(value = nil)
        @instance = true if value
        @value = value || ""
        @ready = false
      end

      def end?
        @value == ";"
      end

      def instance
        raise Nginxtra::Error::ConvertFailed.new("Whoops!") unless ready?
        token = Nginxtra::ConfigConverter::Token.new @value
        reset!
        token
      end

      def <<(c)
        return space! if c =~ /\s/
        return terminal_character!(c) if TERMINAL_CHARACTERS.include? c
        @value << c
      end

      def ready?
        @instance || @ready || ready_string?
      end

      def to_s
        if @value =~ /^\d+$/
          @value
        else
          %{"#{@value}"}
        end
      end

      private
      def ready_string?
        TERMINAL_CHARACTERS.include? @value
      end

      def space!
        return if @value.empty?
        @ready = true
      end

      def terminal_character!(c)
        if @value.empty?
          @value = c
        else
          @next = c
        end

        @ready = true
      end

      def reset!
        if @next
          @value = @next
        else
          @value = ""
        end

        @next = nil
        @ready = false
      end
    end
  end
end
