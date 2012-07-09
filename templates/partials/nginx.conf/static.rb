@config.compile_option "--with-http_gzip_static_module"

server do
  listen(yield(:port) || 80)
  server_name(yield(:server_name) || "localhost")
  root File.absolute_path(File.expand_path(yield(:root) || "."))
  gzip_static "on"
end
