require "spec_helper"

describe Nginxtra::Status do
  let(:base_dir) { File.absolute_path File.expand_path("../..", __FILE__) }
  before { Nginxtra::Status.class_variable_set :@@status, nil }

  describe "with no file to load" do
    before { File.should_receive(:exists?).with(File.join(base_dir, ".nginxtra_status")).and_return(false) }

    it "defaults options to nil" do
      Nginxtra::Status[:last_compile_options].should == nil
      Nginxtra::Status[:random_other_value].should == nil
    end

    it "saves out to a file when options are stored" do
      YAML.should_receive(:dump).with({ :last_compile_options => "--some-option" }).and_return("The YAML dumped content")
      Nginxtra::Status[:last_compile_options] = "--some-option"
      Nginxtra::Status[:last_compile_options].should == "--some-option"
    end
  end

  describe "with a file to load" do
    it "defaults missing options to nil"
    it "returns values stored in the file"
    it "saves out to a file when options are stored"
  end
end
