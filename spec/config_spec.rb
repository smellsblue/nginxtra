require "spec_helper"

describe Nginxtra::Config do
  describe "compile options" do
    it "defaults to auto_semicolon" do
      nginxtra.options[:auto_semicolon].should == true
    end

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
end
