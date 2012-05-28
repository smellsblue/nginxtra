require "thor"

module Nginxtra
  class CLI < Thor
    include Thor::Actions
    desc "compile", "Compiles nginx based on nginxtra.conf.rb"
    method_option "force", :type => :boolean, :banner => "Force compilation to happen", :aliases => "-f"

    def compile
      Nginxtra::Actions::Compile.new(self, Nginxtra::Config.require!, :force => options["force"]).compile
    end
  end
end
