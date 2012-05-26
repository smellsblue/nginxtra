require "spec_helper"

describe Nginxtra::Actions::Compile do
  let(:thor_mock) { Object.new }
  let(:config_mock) { Object.new }

  it "configures based on the passed in config" do
    thor_mock.should_receive(:inside).with(File.absolute_path(File.expand_path("../../src/nginx", __FILE__))).and_yield
    thor_mock.should_receive(:run).with("./configure --prefix=#{File.absolute_path File.expand_path("../../build/nginx", __FILE__)} --option1 --option2")
    config_mock.should_receive(:compile_options).and_return("--option1 --option2")
    compile = Nginxtra::Actions::Compile.new thor_mock, config_mock
    compile.configure
  end
end
