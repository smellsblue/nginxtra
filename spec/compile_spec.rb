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
    expect(thor_mock).to receive(:directory).with("vendor/nginx", src_dir)
    expect(thor_mock).to receive(:inside).with(src_dir).and_yield.at_least(:once)
    expect(thor_mock).to receive(:run).with("sh configure --prefix=#{build_dir} --conf-path=#{config_file} --pid-path=#{pidfile} --option1 --option2") { RunMock.success }
    expect(thor_mock).to receive(:run).with("make") { RunMock.success }
    expect(thor_mock).to receive(:run).with("make install") { RunMock.success }
    allow(thor_mock).to receive(:options).and_return({ "force" => false })
    allow(config_mock).to receive(:compile_options).and_return("--option1 --option2")
    expect(Nginxtra::Status).to receive(:[]).with(:last_compile_options).and_return(nil)
    allow(Time).to receive(:now).and_return(:fake_time)
    allow(Nginxtra::Status).to receive(:[]=).with(:last_compile_options, "--option1 --option2")
    allow(Nginxtra::Status).to receive(:[]=).with(:last_compile_time, :fake_time)
    allow(Nginxtra::Status).to receive(:[]=).with(:last_compile_version, Nginxtra::Config.nginx_version)
    Nginxtra::Actions::Compile.new(thor_mock, config_mock).compile
  end

  it "compiles based on the passed in config when different options were previously compiled" do
    expect(thor_mock).to receive(:directory).with("vendor/nginx", src_dir)
    expect(thor_mock).to receive(:inside).with(src_dir).and_yield.at_least(:once)
    expect(thor_mock).to receive(:run).with("sh configure --prefix=#{build_dir} --conf-path=#{config_file} --pid-path=#{pidfile} --option1 --option2") { RunMock.success }
    expect(thor_mock).to receive(:run).with("make") { RunMock.success }
    expect(thor_mock).to receive(:run).with("make install") { RunMock.success }
    allow(thor_mock).to receive(:options).and_return({ "force" => false })
    allow(config_mock).to receive(:compile_options).and_return("--option1 --option2")
    expect(Nginxtra::Status).to receive(:[]).with(:last_compile_options).and_return("--other-options")
    allow(Time).to receive(:now).and_return(:fake_time)
    expect(Nginxtra::Status).to receive(:[]=).with(:last_compile_options, "--option1 --option2")
    expect(Nginxtra::Status).to receive(:[]=).with(:last_compile_time, :fake_time)
    expect(Nginxtra::Status).to receive(:[]=).with(:last_compile_version, Nginxtra::Config.nginx_version)
    Nginxtra::Actions::Compile.new(thor_mock, config_mock).compile
  end

  it "doesn't compile if the last compiled status indicates it has already compiled with the same options" do
    expect(config_mock).to receive(:compile_options).and_return("--option1 --option2")
    allow(Nginxtra::Status).to receive(:[]).with(:last_compile_options).and_return("--option1 --option2")
    allow(Nginxtra::Status).to receive(:[]).with(:last_compile_version).and_return(Nginxtra::Config.nginx_version)
    expect(thor_mock).to_not receive(:inside)
    expect(thor_mock).to_not receive(:run) { RunMock.success }
    allow(thor_mock).to receive(:options).and_return({ "force" => false })
    expect(thor_mock).to receive(:say).with("nginx compilation is up to date")
    expect(Nginxtra::Status).to_not receive(:[]=)
    Nginxtra::Actions::Compile.new(thor_mock, config_mock).compile
  end

  it "recompiles if force is passed in" do
    expect(thor_mock).to receive(:directory).with("vendor/nginx", src_dir)
    expect(thor_mock).to receive(:inside).with(src_dir).and_yield.at_least(:once)
    expect(thor_mock).to receive(:run).with("sh configure --prefix=#{build_dir} --conf-path=#{config_file} --pid-path=#{pidfile} --option1 --option2") { RunMock.success }
    expect(thor_mock).to receive(:run).with("make") { RunMock.success }
    expect(thor_mock).to receive(:run).with("make install") { RunMock.success }
    allow(thor_mock).to receive(:options).and_return({ "force" => true })
    allow(config_mock).to receive(:compile_options).and_return("--option1 --option2")
    allow(Nginxtra::Status).to receive(:[]).with(:last_compile_options).and_return("--option1 --option2")
    allow(Time).to receive(:now).and_return(:fake_time)
    expect(Nginxtra::Status).to receive(:[]=).with(:last_compile_options, "--option1 --option2")
    expect(Nginxtra::Status).to receive(:[]=).with(:last_compile_time, :fake_time)
    expect(Nginxtra::Status).to receive(:[]=).with(:last_compile_version, Nginxtra::Config.nginx_version)
    Nginxtra::Actions::Compile.new(thor_mock, config_mock).compile
  end
end
