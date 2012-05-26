require "spec_helper"

describe Nginxtra::Util do
  describe "#config_file_path" do
    before { File.should_receive(:absolute_path).with(".").and_return("/home/example/some/path") }

    it "finds the config file if it is in the current directory" do
      File.should_receive(:exists?).with("/home/example/some/path/nginxtra.conf.rb").and_return(true)
      Nginxtra::Util.config_file_path.should == "/home/example/some/path/nginxtra.conf.rb"
    end

    it "finds the config file if it is in the first parent" do
      File.should_receive(:exists?).with("/home/example/some/path/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/home/example/some/nginxtra.conf.rb").and_return(true)
      Nginxtra::Util.config_file_path.should == "/home/example/some/nginxtra.conf.rb"
    end

    it "finds the config file if it is in the second parent" do
      File.should_receive(:exists?).with("/home/example/some/path/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/home/example/some/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/home/example/nginxtra.conf.rb").and_return(true)
      Nginxtra::Util.config_file_path.should == "/home/example/nginxtra.conf.rb"
    end

    it "finds the config file if it is in the third parent" do
      File.should_receive(:exists?).with("/home/example/some/path/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/home/example/some/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/home/example/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/home/nginxtra.conf.rb").and_return(true)
      Nginxtra::Util.config_file_path.should == "/home/nginxtra.conf.rb"
    end

    it "finds the config file if it is in the fourth parent" do
      File.should_receive(:exists?).with("/home/example/some/path/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/home/example/some/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/home/example/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/home/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/nginxtra.conf.rb").and_return(true)
      Nginxtra::Util.config_file_path.should == "/nginxtra.conf.rb"
    end

    it "returns nil if no config file is found" do
      File.should_receive(:exists?).with("/home/example/some/path/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/home/example/some/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/home/example/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/home/nginxtra.conf.rb").and_return(false)
      File.should_receive(:exists?).with("/nginxtra.conf.rb").and_return(false)
      Nginxtra::Util.config_file_path.should == nil
    end
  end
end
