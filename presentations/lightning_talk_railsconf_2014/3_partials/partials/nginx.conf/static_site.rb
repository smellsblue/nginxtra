server do
  listen yield(:port)
  server_name "localhost"

  location "/" do
    root yield(:root)
    index "index.html", "index.htm"
  end
end
