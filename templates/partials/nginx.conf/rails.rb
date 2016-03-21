rails_server = yield(:server) || :passenger
ssl_details = yield :ssl

default_port = if ssl_details
  443
else
  80
end

if rails_server == :passenger && !@passenger_requirements_done
  @config.require_passenger!
  passenger_root!
  passenger_ruby!
  @passenger_requirements_done = true
end

server do
  listen(yield(:port) || default_port)
  server_name(yield(:server_name) || "localhost")
  root File.join(File.absolute_path(File.expand_path(yield(:root) || ".")), "public")
  gzip_static "on"
  passenger_on! if rails_server == :passenger
  rails_env(yield(:environment) || "production")

  if ssl_details
    ssl "on"
    ssl_certificate ssl_details[:ssl_cert]
    ssl_certificate_key ssl_details[:ssl_key]
    @config.compile_option "--with-http_ssl_module"
  end

  yield
end
