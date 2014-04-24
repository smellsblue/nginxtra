nginxtra.config do
  custom_partials File.expand_path("../partials", __FILE__)

  file "nginx.conf" do
    worker_processes 1

    events do
      worker_connections 1024
    end

    http do
      include "mime.types"
      default_type "application/octet-stream"

      base_path = File.expand_path(__FILE__, "..")
      static_site :port => 12345, :root => File.join(base_path, "site_1")
      static_site :port => 11111, :root => File.join(base_path, "site_2")
      static_site :port => 22222, :root => File.join(base_path, "site_3")
    end
  end
end
