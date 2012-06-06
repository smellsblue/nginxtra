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

  it "handles comments on the last line" do
    converter.convert :config => StringIO.new("user    my_user;
# A line comment")
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

  it "handles multiple lines smooshed together" do
    converter.convert :config => StringIO.new("user my_user;worker_processes 1;worker_processes 2;")
    output.string.should == %{nginxtra.config do
  user "my_user"
  worker_processes 1
  worker_processes 2
end
}
  end

  it "handles simple blocks" do
    converter.convert :config => StringIO.new("events {
}")
    output.string.should == %{nginxtra.config do
  events do
  end
end
}
  end

  it "handles simple blocks with content" do
    converter.convert :config => StringIO.new("events {
  worker_connections 10;
}")
    output.string.should == %{nginxtra.config do
  events do
    worker_connections 10
  end
end
}
  end

  it "can manage nested blocks with content" do
    converter.convert :config => StringIO.new("events {
  nested_events {
    deeper_nested_events {
      worker_connections 10;
    }
  }
}")
    output.string.should == %{nginxtra.config do
  events do
    nested_events do
      deeper_nested_events do
        worker_connections 10
      end
    end
  end
end
}
  end
  it "will deal with single line of nested blocks and values" do
    converter.convert :config => StringIO.new("events{value 1;nested_events{deeper_nested_events{worker_connections 10;inner_value 2;}}}")
    output.string.should == %{nginxtra.config do
  events do
    value 1
    nested_events do
      deeper_nested_events do
        worker_connections 10
        inner_value 2
      end
    end
  end
end
}
  end

  it "detects invalidly nested blocks" do
    lambda { converter.convert :config => StringIO.new("events {
  worker_connections 10;") }.should raise_error(Nginxtra::Error::ConvertFailed)
  end

  it "detects bad line endings" do
    lambda { converter.convert :config => StringIO.new("worker_connections 10") }.should raise_error(Nginxtra::Error::ConvertFailed)
  end

  it "detects bad line endings within block" do
    lambda { converter.convert :config => StringIO.new("event { worker_connections 10 }") }.should raise_error(Nginxtra::Error::ConvertFailed)
  end

  it "detects bad line endings with 1 label within block" do
    lambda { converter.convert :config => StringIO.new("event { worker_connections }") }.should raise_error(Nginxtra::Error::ConvertFailed)
  end

  it "fails with blocks with no label" do
    lambda { converter.convert :config => StringIO.new("{ worker_connections 10; }") }.should raise_error(Nginxtra::Error::ConvertFailed)
  end

  it "fails with empty lines" do
    lambda { converter.convert :config => StringIO.new(";") }.should raise_error(Nginxtra::Error::ConvertFailed)
  end
end
