require "spec_helper"

describe Nginxtra::Status do
  describe "with no file to load" do
    xit "defaults options to nil" do
      Nginxtra::Status[:last_compile_options].should == nil
      Nginxtra::Status[:random_other_value].should == nil
    end

    it "saves out to a file when options are stored"
  end

  describe "with a file to load" do
    it "defaults missing options to nil"
    it "returns values stored in the file"
    it "saves out to a file when options are stored"
  end
end
