worker_processes(yield(:worker_processes) || 1)

events do
  worker_connections(yield(:worker_connections) || 1024)
end

http do
  include "mime.types"
  default_type "application/octet-stream"
  sendfile "on"
  keepalive_timout 65
  gzip "on"
  yield
end
