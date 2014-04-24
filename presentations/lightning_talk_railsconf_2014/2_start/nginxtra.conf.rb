nginxtra.config do
  file "nginx.conf" do
    worker_processes 1

    events do
      worker_connections 1024
    end

    http do
      include "mime.types"
      default_type "application/octet-stream"

      server do
        listen 12345
        server_name "localhost"

        location "/" do
          root File.expand_path(__FILE__, "..")
          index "index.html", "index.htm"
        end
      end
    end
  end
end
