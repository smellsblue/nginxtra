require "spec_helper"

describe Nginxtra::Config do
  it "remembers the last config created" do
    Nginxtra::Config.last_config.should == nil
    config1 = nginxtra
    Nginxtra::Config.last_config.should == config1
    config2 = nginxtra
    Nginxtra::Config.last_config.should_not == config1
    Nginxtra::Config.last_config.should == config2
  end

  describe "compile options" do
    it "supports empty compile options" do
      config = nginxtra.config do
      end

      config.compile_options.should == ""
    end

    it "supports options to be defined without --" do
      config = nginxtra.config do
        compile_option "without-http_gzip_module"
      end

      config.compile_options.should == "--without-http_gzip_module"
    end

    it "supports options to be defined with --" do
      config = nginxtra.config do
        compile_option "--without-http_gzip_module"
      end

      config.compile_options.should == "--without-http_gzip_module"
    end

    it "allows multiple options, and preserves the order" do
      config = nginxtra.config do
        compile_option "--without-http_gzip_module"
        compile_option "with-pcre-jit"
        compile_option "--with-select_module"
      end

      config.compile_options.should == "--without-http_gzip_module --with-pcre-jit --with-select_module"
    end

    it "prevents the use of --prefix option" do
      config = nginxtra
      lambda { config.compile_option "--prefix=/usr/share/nginx" }.should raise_error(Nginxtra::Error::InvalidConfig)
      config.compile_options.should == ""
    end

    it "prevents the use of --prefix option embedded with other options" do
      config = nginxtra
      lambda { config.compile_option "--someoption --prefix=/usr/share/nginx --someotheroption" }.should raise_error(Nginxtra::Error::InvalidConfig)
      config.compile_options.should == ""
    end

    it "prevents the use of the --sbin-path option" do
      config = nginxtra
      lambda { config.compile_option "--someoption --sbin-path=something --someotheroption" }.should raise_error(Nginxtra::Error::InvalidConfig)
      config.compile_options.should == ""
    end

    it "prevents the use of the --conf-path option" do
      config = nginxtra
      lambda { config.compile_option "--someoption --conf-path=conf --someotheroption" }.should raise_error(Nginxtra::Error::InvalidConfig)
      config.compile_options.should == ""
    end

    it "prevents the use of the --pid-path option" do
      config = nginxtra
      lambda { config.compile_option "--someoption --pid-path=conf --someotheroption" }.should raise_error(Nginxtra::Error::InvalidConfig)
      config.compile_options.should == ""
    end
  end

  describe "nginx.conf definition" do
    it "supports no file definition" do
      config = nginxtra.config do
      end

      config.files.should == []
    end

    it "supports empty definition" do
      config = nginxtra.config do
        file "nginx.conf" do
        end
      end

      config.files.should == ["nginx.conf"]
      config.file_contents("nginx.conf").should == ""
    end

    it "allows simple line definitions" do
      config = nginxtra.config do
        file "nginx.conf" do
          config_line "user my_user"
          config_line "worker_processes 42"
        end
      end

      config.files.should == ["nginx.conf"]
      config.file_contents("nginx.conf").should == "user my_user;
worker_processes 42;"
    end

    it "allows line definitions without semicolon" do
      config = nginxtra.config do
        file "nginx.conf" do
          bare_config_line "user my_user"
          bare_config_line "worker_processes 42"
        end
      end

      config.files.should == ["nginx.conf"]
      config.file_contents("nginx.conf").should == "user my_user
worker_processes 42"
    end

    it "allows block definitions" do
      config = nginxtra.config do
        file "nginx.conf" do
          config_block "events" do
            config_line "worker_connections 4242"
          end
        end
      end

      config.files.should == ["nginx.conf"]
      config.file_contents("nginx.conf").should == "events {
    worker_connections 4242;
}"
    end

    it "supports empty block definitions" do
      config = nginxtra.config do
        file "nginx.conf" do
          config_block "events"
        end
      end

      config.files.should == ["nginx.conf"]
      config.file_contents("nginx.conf").should == "events {
}"
    end

    it "allows arbitrary blocks and lines" do
      config = nginxtra.config do
        file "nginx.conf" do
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
      end

      config.files.should == ["nginx.conf"]
      config.file_contents("nginx.conf").should == "user my_user;
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

    it "allows defining multiple config files" do
      config = nginxtra.config do
        file "nginx.conf" do
          nginx_contents
        end

        file "other.conf" do
          other_contents
        end
      end

      config.files.should =~ ["other.conf", "nginx.conf"]
      config.file_contents("nginx.conf").should == "nginx_contents;"
      config.file_contents("other.conf").should == "other_contents;"
    end
  end

  describe "path" do
    before { File.should_receive(:absolute_path).with(".").and_return("/home/example/some/path") }

    it "finds the config file if it is in the current directory" do
      File.should_receive(:exists?).with("/home/example/some/path/nginxtra.conf.rb").and_return(true)
      Nginxtra::Config.path.should == "/home/example/some/path/nginxtra.conf.rb"
    end

    it "finds the config file if it is in the first parent" do
      File.should_receive(:exists?).with("/home/example/some/path/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/home/example/some/nginxtra.conf.rb").and_return(true)
      Nginxtra::Config.path.should == "/home/example/some/nginxtra.conf.rb"
    end

    it "finds the config file if it is in the second parent" do
      File.should_receive(:exists?).with("/home/example/some/path/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/home/example/some/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/home/example/nginxtra.conf.rb").and_return(true)
      Nginxtra::Config.path.should == "/home/example/nginxtra.conf.rb"
    end

    it "finds the config file if it is in the third parent" do
      File.should_receive(:exists?).with("/home/example/some/path/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/home/example/some/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/home/example/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/home/nginxtra.conf.rb").and_return(true)
      Nginxtra::Config.path.should == "/home/nginxtra.conf.rb"
    end

    it "finds the config file if it is in the fourth parent" do
      File.should_receive(:exists?).with("/home/example/some/path/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/home/example/some/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/home/example/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/home/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/nginxtra.conf.rb").and_return(true)
      Nginxtra::Config.path.should == "/nginxtra.conf.rb"
    end

    it "returns nil if no config file is found" do
      File.should_receive(:exists?).with("/home/example/some/path/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/home/example/some/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/home/example/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/home/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/nginxtra.conf.rb").and_return(false)
      Nginxtra::Config.path.should == nil
    end
  end

  describe "require!" do
    it "should require the config and then return the last config" do
      config = nil
      Nginxtra::Config.should_receive(:path).and_return("/a/fake/path")
      Nginxtra::Config.should_receive(:require).with("/a/fake/path") do
        config = nginxtra
        nil
      end
      File.should_receive(:exists?).with("/a/fake/path").and_return(true)
      Nginxtra::Config.require!.should == config
    end

    it "raises an error if the config file cannot be found" do
      Nginxtra::Config.should_receive(:path).and_return(nil)
      lambda { Nginxtra::Config.require! }.should raise_error(Nginxtra::Error::MissingConfig)
    end

    it "raises an error if the config file doesn't specify any configuration" do
      Nginxtra::Config.should_receive(:path).and_return("/a/fake/path")
      Nginxtra::Config.should_receive(:require).with("/a/fake/path") do
        nil
      end
      Nginxtra::Config.should_receive(:last_config).and_return(nil)
      File.should_receive(:exists?).with("/a/fake/path").and_return(true)
      lambda { Nginxtra::Config.require! }.should raise_error(Nginxtra::Error::InvalidConfig)
    end

    it "allows specifying a specific configuration file" do
      config = nil
      Nginxtra::Config.should_not_receive(:path)
      Nginxtra::Config.should_receive(:require).with("/a/fake/path") do
        config = nginxtra
        nil
      end
      File.should_receive(:exists?).with("/a/fake/path").and_return(true)
      Nginxtra::Config.require!("/a/fake/path").should == config
    end
  end

  describe "auto config capabilities" do
    before do
      Nginxtra::Config.stub(:passenger_spec) do
        o = Object.new
        o.stub(:gem_dir).and_return("PASSENGER_ROOT")
        o
      end
      Nginxtra::Config.stub(:ruby_path).and_return("PASSENGER_RUBY")
    end

    it "allows very simple rails configuration" do
      config = nginxtra.simple_config do
        rails
      end
      config.files.should == ["nginx.conf"]
      config.file_contents("nginx.conf").should == "worker_processes 1;

events {
    worker_connections 1024;
}

http {
    passenger_root PASSENGER_ROOT;
    passenger_ruby PASSENGER_RUBY;
    include mime.types;
    default_type application/octet-stream;
    sendfile on;
    keepalive_timout 65;
    gzip on;

    server {
        listen 80;
        server_name localhost;
        root #{File.absolute_path "public"};
        gzip_static on;
        passenger_enabled on;
    }
}"
    end

    it "allows multiple rails servers to be specified" do
      config = nginxtra.simple_config do
        rails
        rails :port => 8080, :server_name => "otherserver.com", :root => "/path/to/rails"
      end
      config.files.should == ["nginx.conf"]
      config.file_contents("nginx.conf").should == "worker_processes 1;

events {
    worker_connections 1024;
}

http {
    passenger_root PASSENGER_ROOT;
    passenger_ruby PASSENGER_RUBY;
    include mime.types;
    default_type application/octet-stream;
    sendfile on;
    keepalive_timout 65;
    gzip on;

    server {
        listen 80;
        server_name localhost;
        root #{File.absolute_path "public"};
        gzip_static on;
        passenger_enabled on;
    }

    server {
        listen 8080;
        server_name otherserver.com;
        root /path/to/rails/public;
        gzip_static on;
        passenger_enabled on;
    }
}"
    end
  end
end
