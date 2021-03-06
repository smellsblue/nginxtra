# Note: This gemspec generated by the Rakefile
require "rubygems/package_task"

Gem::Specification.new do |s|
  s.name           = "nginxtra"
  s.version        = "1.10.1.13"
  s.summary        = "Wrapper of nginx for easy install and use."
  s.description    = "This gem is intended to provide an easy to use configuration file that will automatically be " \
                     "used to compile nginx and configure the configuration."
  s.author         = "Mike Virata-Stone"
  s.email          = "mike@virata-stone.com"
  s.license        = "nginx"
  s.files          = FileList["bin/**/*", "lib/**/*", "templates/**/*", "vendor/**/*"]
  s.require_path   = "lib"
  s.bindir         = "bin"
  s.executables    = %w(nginxtra nginxtra_rails)
  s.homepage       = "https://github.com/smellsblue/nginxtra"
  s.add_runtime_dependency "thor", "~> 0.16"
  s.add_development_dependency "nokogiri", "~> 1.6"
  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "rspec", "~> 3.3"
  s.add_development_dependency "rubocop", "~> 0.38.0"
end
