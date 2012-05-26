require "spec_helper"

describe Nginxtra::Actions::Compile do
  let(:thor_mock) { Object.new }
  let(:config_mock) { Object.new }
  let(:src_dir) { File.absolute_path File.expand_path("../../src/nginx", __FILE__) }
  let(:build_dir) { File.absolute_path File.expand_path("../../build/nginx", __FILE__) }

  it "compiles based on the passed in config" do
    thor_mock.stub(:inside).with(src_dir).and_yield
    thor_mock.should_receive(:run).with("./configure --prefix=#{build_dir} --option1 --option2")
    thor_mock.should_receive(:run).with("make")
    thor_mock.should_receive(:run).with("make install")
    config_mock.should_receive(:compile_options).and_return("--option1 --option2")
    Nginxtra::Actions::Compile.new(thor_mock, config_mock).compile
  end
end
