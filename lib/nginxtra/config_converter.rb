module Nginxtra
  class ConfigConverter
    def initialize(output)
      @converted = false
      @output = output
      @indentation = Nginxtra::ConfigConverter::Indentation.new
    end

    def convert(options)
      raise Nginxtra::Error::ConvertFailed.new("The convert method can only be called once!") if converted?
      header
      compile_options options[:binary_status]
      config_file options[:config]
      footer
      converted!
    end

    private
    def header
      @output.puts "nginxtra.config do"
      @indentation + 1
    end

    def compile_options(status)
      return unless status
      options = (status[/^configure arguments:\s*(.*)$/, 1] || "").strip
      return if options.empty?
      options = options.split /\s+/
      process_passenger_compile_options! options

      options.each do |option|
        next if invalid_compile_option? option
        @output.print @indentation
        @output.puts %{compile_option "#{option}"}
      end
    end

    def process_passenger_compile_options!(options)
      return if options.select { |x| x =~ /^--add-module.*\/passenger.*/ }.empty?
      @output.print @indentation
      @output.puts "require_passenger!"

      options.delete_if do |x|
        next true if x =~ /^--add-module.*\/passenger.*/
        ["--with-http_ssl_module", "--with-http_gzip_static_module", "--with-cc-opt=-Wno-error"].include? x
      end
    end

    def invalid_compile_option?(option)
      return true if option =~ /--prefix=/
      return true if option =~ /--sbin-path=/
      return true if option =~ /--conf-path=/
      return true if option =~ /--pid-path=/
      false
    end

    def config_file(input)
      return unless input
      @output.print @indentation
      @output.puts %{file "nginx.conf" do}
      @indentation + 1
      line = Nginxtra::ConfigConverter::Line.new @indentation, @output

      each_token(input) do |token|
        line << token

        if line.terminated?
          line.puts
          line = Nginxtra::ConfigConverter::Line.new @indentation, @output
        end
      end

      raise Nginxtra::Error::ConvertFailed.new("Unexpected end of file!") unless line.empty?
      @indentation - 1
      @output.print @indentation
      @output.puts "end"
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
      raise Nginxtra::Error::ConvertFailed.new("Unexpected end of file in mid token!") unless token.value.empty?
    end

    def chomp_comment(input)
      while c = input.read(1)
        break if c == "\n"
      end
    end

    def footer
      @indentation - 1
      @output.puts "end"
      raise Nginxtra::Error::ConvertFailed.new("Missing end blocks!") unless @indentation.done?
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

      def terminal_character?
        TERMINAL_CHARACTERS.include? @value
      end

      def end?
        @value == ";"
      end

      def block_start?
        @value == "{"
      end

      def block_end?
        @value == "}"
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
        @instance || @ready || terminal_character?
      end

      def to_s
        if @value =~ /^\d+$/
          @value
        else
          %{"#{@value}"}
        end
      end

      private
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

    class Line
      def initialize(indentation, output)
        @indentation = indentation
        @output = output
        @tokens = []
      end

      def <<(token)
        @tokens << token
      end

      def empty?
        @tokens.empty?
      end

      def terminated?
        @tokens.last.terminal_character?
      end

      def puts
        if @tokens.last.end?
          puts_line
        elsif @tokens.last.block_start?
          puts_block_start
        elsif @tokens.last.block_end?
          puts_block_end
        else
          raise Nginxtra::Error::ConvertFailed.new "Can't puts invalid line!"
        end
      end

      private
      def passenger?
        ["passenger_root", "passenger_ruby", "passenger_enabled"].include? @tokens.first.value
      end

      def puts_line
        raise Nginxtra::Error::ConvertFailed.new("line must have a first label!") unless @tokens.length > 1
        return puts_passenger if passenger?
        print_indentation
        print_first
        print_args
        print_newline
      end

      def puts_passenger
        print_indentation

        if @tokens.first.value == "passenger_root"
          print_newline "passenger_root!"
        elsif @tokens.first.value == "passenger_ruby"
          print_newline "passenger_ruby!"
        elsif @tokens.first.value == "passenger_enabled"
          print_newline "passenger_on!"
        else
          raise Nginxtra::Error::ConvertFailed.new("Whoops!")
        end
      end

      def puts_block_start
        raise Nginxtra::Error::ConvertFailed.new("Block start must have a first label!") unless @tokens.length > 1
        print_indentation
        print_first
        print_args
        print_newline(" do")
        indent
      end

      def puts_block_end
        raise Nginxtra::Error::ConvertFailed.new("Block end can't have labels!") unless @tokens.length == 1
        unindent
        print_indentation
        print_newline("end")
      end

      def print_indentation
        @output.print @indentation.to_s
      end

      def print_first
        @output.print @tokens.first.value
      end

      def print_args
        args = @tokens[1..-2]
        return if args.empty?
        @output.print " "
        @output.print args.map(&:to_s).join(", ")
      end

      def print_newline(value = "")
        @output.puts value
      end

      def indent
        @indentation + 1
      end

      def unindent
        @indentation - 1
      end
    end

    class Indentation
      attr_reader :value

      def initialize
        @value = 0
      end

      def done?
        @value == 0
      end

      def -(amount)
        self + (-amount)
      end

      def +(amount)
        @value += amount
        raise Nginxtra::Error::ConvertFailed.new("Missing block end!") if @value < 0
        @value
      end

      def to_s
        "  " * @value
      end
    end
  end
end
