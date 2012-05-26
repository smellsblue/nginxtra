require "spec_helper"

describe Nginxtra::Config do
  describe "compile options" do
    it "supports empty compile options" do
      config = nginxtra.config do
      end

      config.compile_options.should == ""
    end

    it "supports options to be defined without --" do
      config = nginxtra.config do
        option "without-http_gzip_module"
      end

      config.compile_options.should == "--without-http_gzip_module"
    end

    it "supports options to be defined with --" do
      config = nginxtra.config do
        option "--without-http_gzip_module"
      end

      config.compile_options.should == "--without-http_gzip_module"
    end

    it "allows multiple options, and preserves the order" do
      config = nginxtra.config do
        option "--without-http_gzip_module"
        option "with-pcre-jit"
        option "--with-select_module"
      end

      config.compile_options.should == "--without-http_gzip_module --with-pcre-jit --with-select_module"
    end

    it "prevents the use of --prefix option" do
      config = nginxtra
      lambda { config.option "--prefix=/usr/share/nginx" }.should raise_error(Nginxtra::Error::InvalidConfig)
      config.compile_options.should == ""
    end

    it "prevents the use of --prefix option embedded with other options" do
      config = nginxtra
      lambda { config.option "--someoption --prefix=/usr/share/nginx --someotheroption" }.should raise_error(Nginxtra::Error::InvalidConfig)
      config.compile_options.should == ""
    end

    it "prevents the use of the --sbin-path option" do
      config = nginxtra
      lambda { config.option "--someoption --sbin-path=something --someotheroption" }.should raise_error(Nginxtra::Error::InvalidConfig)
      config.compile_options.should == ""
    end

    it "prevents the use of the --conf-path option" do
      config = nginxtra
      lambda { config.option "--someoption --conf-path=conf --someotheroption" }.should raise_error(Nginxtra::Error::InvalidConfig)
      config.compile_options.should == ""
    end
  end

  describe "nginx.conf definition" do
    it "supports empty definition" do
      config = nginxtra.config do
      end

      config.config_contents.should == ""
    end

    it "allows simple line definitions" do
      config = nginxtra.config do
        config_line "user my_user"
        config_line "worker_processes 42"
      end

      config.config_contents.should == "user my_user;
worker_processes 42;"
    end

    it "allows line definitions without semicolon" do
      config = nginxtra.config do
        bare_config_line "user my_user"
        bare_config_line "worker_processes 42"
      end

      config.config_contents.should == "user my_user
worker_processes 42"
    end

    it "allows block definitions" do
      config = nginxtra.config do
        config_block "events" do
          config_line "worker_connections 4242"
        end
      end

      config.config_contents.should == "events {
worker_connections 4242;
}"
    end

    it "supports empty block definitions" do
      config = nginxtra.config do
        config_block "events"
      end

      config.config_contents.should == "events {
}"
    end

    it "allows arbitrary blocks and lines" do
      config = nginxtra.config do
        user "my_user"
        worker_processes 42

        events do
          worker_connections 512
        end

        http do
          location "= /robots.txt" do
            access_log "off"
          end

          location "/" do
            try_files "$uri", "$uri.html"
          end
        end
      end

      config.config_contents.should == "user my_user;
worker_processes 42;
events {
worker_connections 512;
}
http {
location = /robots.txt {
access_log off;
}
location / {
try_files $uri $uri.html;
}
}"
    end
  end
end
