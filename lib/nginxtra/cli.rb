require "thor"

module Nginxtra
  class CLI < Thor
    desc "compile", "Compiles nginx based on nginxtra.conf.rb"

    def compile
      puts "This will compile nginx"
    end
  end
end
