version = File.read(File.expand_path("../VERSION", __FILE__)).strip

Gem::Specification.new do |s|
  s.name           = "nginxtra"
  s.version        = version
  s.summary        = "Wrapper of nginx for easy install and use."
  s.description    = "This gem is intended to provide an easy to use configuration file that will automatically be used to compile nginx and configure the configuration."
  s.author         = "Mike Virata-Stone"
  s.email          = "reasonnumber@gmail.com"
  s.files          = `git ls-files VERSION bin lib src`.split("\n")
  s.require_path   = "lib"
  s.bindir         = "bin"
  s.executables    = ["nginxtra"]
  s.homepage       = "http://reasonnumber.com/cartoonist"
  s.add_dependency "thor", "~> 0.15.0"
end
