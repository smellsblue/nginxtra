require "spec_helper"
require "stringio"

describe Nginxtra::ConfigConverter do
  let(:output) { StringIO.new }
  let(:converter) { Nginxtra::ConfigConverter.new output }

  it "raises an error if parsing happens twice" do
    converter.convert :config => StringIO.new("")
    lambda { converter.convert :config => StringIO.new("") }.should raise_error(Nginxtra::Error::ConvertFailed)
  end

  it "converts empty config to a simple config file" do
    converter.convert :config => StringIO.new("")
    output.string.should == "nginxtra.config do
end
"
  end
end
