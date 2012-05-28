require "spec_helper"

describe Nginxtra::Status do
  let(:base_dir) { File.absolute_path File.expand_path("../..", __FILE__) }
  let(:status_file) { File.join(base_dir, ".nginxtra_status") }
  before { Nginxtra::Status.class_variable_set :@@status, nil }

  describe "with no file to load" do
    before { File.should_receive(:exists?).with(status_file).and_return(false) }

    it "defaults options to nil" do
      Nginxtra::Status[:last_compile_options].should == nil
      Nginxtra::Status[:random_other_value].should == nil
    end

    it "saves out to a file when options are stored" do
      YAML.should_receive(:dump).with({ :last_compile_options => "--some-option" }).and_return("The YAML dumped content")
      File.should_receive(:write).with(status_file, "The YAML dumped content")
      Nginxtra::Status[:last_compile_options] = "--some-option"
      Nginxtra::Status[:last_compile_options].should == "--some-option"
    end
  end

  describe "with a file to load" do
    before do
      File.should_receive(:exists?).with(status_file).and_return(true)
      File.should_receive(:read).with(status_file).and_return(YAML.dump({ :last_compile_options => "--original-option", :other_option => "something" }))
    end

    it "defaults missing options to nil" do
      Nginxtra::Status[:missing_option].should == nil
    end

    it "returns values stored in the file" do
      Nginxtra::Status[:last_compile_options].should == "--original-option"
      Nginxtra::Status[:other_option].should == "something"
    end

    it "saves out to a file when new options are stored" do
      YAML.should_receive(:dump).with({ :last_compile_options => "--original-option", :other_option => "something", :new_option => "new value" }).and_return("The YAML dumped content")
      File.should_receive(:write).with(status_file, "The YAML dumped content")
      Nginxtra::Status[:new_option] = "new value"
      Nginxtra::Status[:new_option].should == "new value"
      Nginxtra::Status[:last_compile_options].should == "--original-option"
      Nginxtra::Status[:other_option].should == "something"
    end

    it "saves out to a file when old options are updated" do
      YAML.should_receive(:dump).with({ :last_compile_options => "--some-option", :other_option => "something" }).and_return("The YAML dumped content")
      File.should_receive(:write).with(status_file, "The YAML dumped content")
      Nginxtra::Status[:last_compile_options] = "--some-option"
      Nginxtra::Status[:last_compile_options].should == "--some-option"
      Nginxtra::Status[:other_option].should == "something"
    end
  end
end
