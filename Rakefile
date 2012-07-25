require File.expand_path("../lib/nginxtra/version.rb", __FILE__)

def system_exec(cmd)
  puts "Executing: #{cmd}"
  puts %x[#{cmd}]
end

module Nginxtra
  class Gem
    class << self
      def to_s
        "nginxtra-#{Nginxtra::Version}.gem"
      end
    end
  end
end

task :default => :install

task :generate do
  File.write File.expand_path("../bin/nginxtra", __FILE__), %{#!/usr/bin/env ruby
require "rubygems"
gem "nginxtra", "= #{Nginxtra::Version}"
require "nginxtra"
Nginxtra::CLI.start
}
end

task :build => :generate do
  puts "Building nginxtra"
  system_exec "gem build nginxtra.gemspec"
end

task :install => :build do
  puts "Installing nginxtra"
  system_exec "gem install --no-ri --no-rdoc #{Nginxtra::Gem}"
end

task :tag do
  puts "Tagging nginxtra"
  system_exec "git tag -a #{Nginxtra::Version} -m 'Version #{Nginxtra::Version}' && git push --tags"
end

task :push => :build do
  puts "Pushing nginxtra"
  system_exec "gem push #{Nginxtra::Gem}"
end
