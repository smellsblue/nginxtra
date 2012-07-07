def system_exec(cmd)
  puts "Executing: #{cmd}"
  puts %x[#{cmd}]
end

class Nginxtra
  class << self
    def version
      File.read(File.expand_path("../VERSION", __FILE__)).strip
    end

    def gem
      "nginxtra-#{version}.gem"
    end
  end
end

task :default => :install

task :generate do
  File.write File.expand_path("../bin/nginxtra", __FILE__), %{#!/usr/bin/env ruby
require "rubygems"
gem "nginxtra", "= #{Nginxtra.version}"
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
  system_exec "gem install --no-ri --no-rdoc #{Nginxtra.gem}"
end

task :tag do
  puts "Tagging nginxtra"
  system_exec "git tag -a #{Nginxtra.version} -m 'Version #{Nginxtra.version}' && git push --tags"
end

task :push => :build do
  puts "Pushing nginxtra"
  system_exec "gem push #{Nginxtra.gem}"
end
