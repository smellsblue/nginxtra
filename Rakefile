def system_exec(cmd)
  puts %x[#{cmd}]
end

class Nginxtra
  class << self
    def version
      File.read(File.join(File.dirname(__FILE__), "VERSION")).strip
    end

    def gem
      "nginxtra-#{version}.gem"
    end
  end
end

task :default => :install

task :build do
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
