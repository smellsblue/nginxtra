require "spec_helper"

describe Nginxtra::Actions::Compile do
  let(:thor_mock) { Object.new }
  let(:config_mock) { Object.new }
  let(:base_dir) { File.absolute_path File.expand_path("~/.nginxtra") }
  let(:nginx_dir) { File.join base_dir, "nginx-#{Nginxtra::Config.nginx_version}" }
  let(:src_dir) { File.join nginx_dir, "src" }
  let(:build_dir) { File.join nginx_dir, "build" }
  let(:pidfile) { File.join base_dir, ".nginx_pid" }
  let(:config_file) { File.join base_dir, "conf/nginx.conf" }

  it "compiles based on the passed in config" do
    thor_mock.should_receive(:directory).with("src/nginx", src_dir)
    thor_mock.should_receive(:inside).with(src_dir).and_yield.at_least(:once)
    thor_mock.should_receive(:run).with("sh configure --prefix=#{build_dir} --conf-path=#{config_file} --pid-path=#{pidfile} --option1 --option2")
    thor_mock.should_receive(:run).with("make")
    thor_mock.should_receive(:run).with("make install")
    thor_mock.stub(:options).and_return({ "force" => false })
    config_mock.stub(:compile_options).and_return("--option1 --option2")
    Nginxtra::Status.should_receive(:[]).with(:last_compile_options).and_return(nil)
    Time.stub(:now).and_return(:fake_time)
    Nginxtra::Status.should_receive(:[]=).with(:last_compile_options, "--option1 --option2")
    Nginxtra::Status.should_receive(:[]=).with(:last_compile_time, :fake_time)
    Nginxtra::Actions::Compile.new(thor_mock, config_mock).compile
  end

  it "compiles based on the passed in config when different options were previously compiled" do
    thor_mock.should_receive(:directory).with("src/nginx", src_dir)
    thor_mock.should_receive(:inside).with(src_dir).and_yield.at_least(:once)
    thor_mock.should_receive(:run).with("sh configure --prefix=#{build_dir} --conf-path=#{config_file} --pid-path=#{pidfile} --option1 --option2")
    thor_mock.should_receive(:run).with("make")
    thor_mock.should_receive(:run).with("make install")
    thor_mock.stub(:options).and_return({ "force" => false })
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
    thor_mock.stub(:options).and_return({ "force" => false })
    thor_mock.should_receive(:say).with("nginx compilation is up to date")
    Nginxtra::Status.should_not_receive(:[]=)
    Nginxtra::Actions::Compile.new(thor_mock, config_mock).compile
  end

  it "recompiles if force is passed in" do
    thor_mock.should_receive(:directory).with("src/nginx", src_dir)
    thor_mock.should_receive(:inside).with(src_dir).and_yield.at_least(:once)
    thor_mock.should_receive(:run).with("sh configure --prefix=#{build_dir} --conf-path=#{config_file} --pid-path=#{pidfile} --option1 --option2")
    thor_mock.should_receive(:run).with("make")
    thor_mock.should_receive(:run).with("make install")
    thor_mock.stub(:options).and_return({ "force" => true })
    config_mock.stub(:compile_options).and_return("--option1 --option2")
    Nginxtra::Status.stub(:[]).with(:last_compile_options).and_return("--option1 --option2")
    Time.stub(:now).and_return(:fake_time)
    Nginxtra::Status.should_receive(:[]=).with(:last_compile_options, "--option1 --option2")
    Nginxtra::Status.should_receive(:[]=).with(:last_compile_time, :fake_time)
    Nginxtra::Actions::Compile.new(thor_mock, config_mock).compile
  end
end
