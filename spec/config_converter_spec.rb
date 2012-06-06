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
    output.string.should == %{nginxtra.config do
end
}
  end

  it "converts simple config lines to config file" do
    converter.convert :config => StringIO.new("user    my_user;
")
    output.string.should == %{nginxtra.config do
  user "my_user"
end
}
  end

  it "ignores comments in a line" do
    converter.convert :config => StringIO.new("# A header comment
user    my_user; # A line comment
")
    output.string.should == %{nginxtra.config do
  user "my_user"
end
}
  end

  it "converts multiple simple lines" do
    converter.convert :config => StringIO.new("  user    my_user;

worker_processes     1;  

")
    output.string.should == %{nginxtra.config do
  user "my_user"
  worker_processes 1
end
}
  end
end
