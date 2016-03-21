require "spec_helper"

describe Nginxtra::Status do
  let(:base_dir) { File.absolute_path File.expand_path("~/.nginxtra") }
  let(:status_file) { File.join(base_dir, ".nginxtra_status") }
  before { Nginxtra::Status.class_variable_set :@@status, nil }

  describe "with no file to load" do
    before { expect(File).to receive(:exists?).with(status_file).and_return(false) }

    it "defaults options to nil" do
      expect(Nginxtra::Status[:last_compile_options]).to be_nil
      expect(Nginxtra::Status[:random_other_value]).to be_nil
    end

    it "saves out to a file when options are stored" do
      expect(YAML).to receive(:dump).with({ :last_compile_options => "--some-option" }).and_return("The YAML dumped content")
      fake_file = Object.new
      expect(fake_file).to receive(:<<).with("The YAML dumped content")
      expect(File).to receive(:open).with(status_file, "w").and_yield(fake_file)
      Nginxtra::Status[:last_compile_options] = "--some-option"
      expect(Nginxtra::Status[:last_compile_options]).to eq "--some-option"
    end
  end

  describe "with a file to load" do
    before do
      expect(File).to receive(:exists?).with(status_file).and_return(true)
      expect(File).to receive(:read).with(status_file).and_return(YAML.dump({ :last_compile_options => "--original-option", :other_option => "something" }))
    end

    it "defaults missing options to nil" do
      expect(Nginxtra::Status[:missing_option]).to be_nil
    end

    it "returns values stored in the file" do
      expect(Nginxtra::Status[:last_compile_options]).to eq "--original-option"
      expect(Nginxtra::Status[:other_option]).to eq "something"
    end

    it "saves out to a file when new options are stored" do
      expect(YAML).to receive(:dump).with({ :last_compile_options => "--original-option", :other_option => "something", :new_option => "new value" }).and_return("The YAML dumped content")
      fake_file = Object.new
      expect(fake_file).to receive(:<<).with("The YAML dumped content")
      expect(File).to receive(:open).with(status_file, "w").and_yield(fake_file)
      Nginxtra::Status[:new_option] = "new value"
      expect(Nginxtra::Status[:new_option]).to eq "new value"
      expect(Nginxtra::Status[:last_compile_options]).to eq "--original-option"
      expect(Nginxtra::Status[:other_option]).to eq "something"
    end

    it "saves out to a file when old options are updated" do
      expect(YAML).to receive(:dump).with({ :last_compile_options => "--some-option", :other_option => "something" }).and_return("The YAML dumped content")
      fake_file = Object.new
      expect(fake_file).to receive(:<<).with("The YAML dumped content")
      expect(File).to receive(:open).with(status_file, "w").and_yield(fake_file)
      Nginxtra::Status[:last_compile_options] = "--some-option"
      expect(Nginxtra::Status[:last_compile_options]).to eq "--some-option"
      expect(Nginxtra::Status[:other_option]).to eq "something"
    end
  end
end
