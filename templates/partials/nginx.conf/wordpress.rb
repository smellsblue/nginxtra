raise Nginxtra::Error::InvalidConfig.new("The WordPress partial is currently an untested stub.")

server do
  listen(yield(:port) || 80)
  server_name(yield(:server_name) || "localhost")
  root File.absolute_path(File.expand_path(yield(:root) || "."))
  index "index.php"
  client_max_body_size "50m"

  location "= /favicon.ico" do
    log_not_found "off"
    access_log "off"
  end

  location "= /robots.txt" do
    allow "all"
    log_not_found "off"
    access_log "off"
  end

  location "/" do
    try_files "$uri", "$uri/", "/index.php"
  end

  location "~ \.php$" do
    # NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini
    include "fastcgi.conf"
    fastcgi_intercept_errors "on"
    fastcgi_pass "unix:/var/run/php-fastcgi/php-fastcgi.socket"
  end

  location "~* \.(js|css|png|jpg|jpeg|gif|ico)$" do
    expires "max"
    log_not_found "off"
  end
end
