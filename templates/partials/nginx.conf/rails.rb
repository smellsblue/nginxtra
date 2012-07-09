rails_server = yield(:server) || :passenger

if rails_server == :passenger && !@passenger_requirements_done
  @config.require_passenger!
  passenger_root!
  passenger_ruby!
  @passenger_requirements_done = true
end

server do
  listen(yield(:port) || 80)
  server_name(yield(:server_name) || "localhost")
  root File.join(File.absolute_path(File.expand_path(yield(:root) || ".")), "public")
  gzip_static "on"
  passenger_on! if rails_server == :passenger
end
