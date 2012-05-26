require "thor"

module Nginxtra
  class CLI < Thor
    include Thor::Actions
    desc "compile", "Compiles nginx based on nginxtra.conf.rb"

    def compile
      Nginxtra::Actions::Compile.new(self, Nginxtra::Config.require!).compile
    end
  end
end
