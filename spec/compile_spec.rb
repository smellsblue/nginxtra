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
    config_mock.stub(:compile_options).and_return("--option1 --option2")
    Nginxtra::Status.should_receive(:[]).with(:last_compile_options).and_return(nil)
    Time.stub(:now).and_return(:fake_time)
    Nginxtra::Status.should_receive(:[]=).with(:last_compile_options, "--option1 --option2")
    Nginxtra::Status.should_receive(:[]=).with(:last_compile_time, :fake_time)
    Nginxtra::Actions::Compile.new(thor_mock, config_mock).compile
  end

  it "compiles based on the passed in config when different options were previously compiled" do
    thor_mock.stub(:inside).with(src_dir).and_yield
    thor_mock.should_receive(:run).with("./configure --prefix=#{build_dir} --option1 --option2")
    thor_mock.should_receive(:run).with("make")
    thor_mock.should_receive(:run).with("make install")
    config_mock.stub(:compile_options).and_return("--option1 --option2")
    Nginxtra::Status.should_receive(:[]).with(:last_compile_options).and_return("--other-options")
    Time.stub(:now).and_return(:fake_time)
    Nginxtra::Status.should_receive(:[]=).with(:last_compile_options, "--option1 --option2")
    Nginxtra::Status.should_receive(:[]=).with(:last_compile_time, :fake_time)
    Nginxtra::Actions::Compile.new(thor_mock, config_mock).compile
  end

  it "doesn't compile if the last compiled status indicates it has already compiled with the same options" do
    config_mock.should_receive(:compile_options).and_return("--option1 --option2")
    Nginxtra::Status.stub(:[]).with(:last_compile_options).and_return("--option1 --option2")
    thor_mock.should_not_receive(:inside)
    thor_mock.should_not_receive(:run)
    thor_mock.should_receive(:say).with("nginx compilation is up to date")
    Nginxtra::Status.should_not_receive(:[]=)
    Nginxtra::Actions::Compile.new(thor_mock, config_mock).compile
  end

  it "recompiles if force is passed in" do
    thor_mock.stub(:inside).with(src_dir).and_yield
    thor_mock.should_receive(:run).with("./configure --prefix=#{build_dir} --option1 --option2")
    thor_mock.should_receive(:run).with("make")
    thor_mock.should_receive(:run).with("make install")
    config_mock.stub(:compile_options).and_return("--option1 --option2")
    Nginxtra::Status.stub(:[]).with(:last_compile_options).and_return("--option1 --option2")
    Time.stub(:now).and_return(:fake_time)
    Nginxtra::Status.should_receive(:[]=).with(:last_compile_options, "--option1 --option2")
    Nginxtra::Status.should_receive(:[]=).with(:last_compile_time, :fake_time)
    Nginxtra::Actions::Compile.new(thor_mock, config_mock, :force => true).compile
  end
end
