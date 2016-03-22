require "spec_helper"

module Nginxtra
  module ActionSpec
    class FooAction
      include Nginxtra::Action
      public :force?, :without_force
    end

    class BarAction
      include Nginxtra::Action
      public :force?
    end
  end
end

describe Nginxtra::Action do
  describe "#without_force" do
    let(:thor) { double(options: options) }
    let(:options) { { "force" => force } }
    let(:config) { double }
    let(:foo) { Nginxtra::ActionSpec::FooAction.new(thor, config) }
    let(:bar) { Nginxtra::ActionSpec::BarAction.new(thor, config) }

    context "when force is false" do
      let(:force) { false }

      it "force will always be false" do
        expect(foo.force?).to be_falsey
        expect(bar.force?).to be_falsey

        foo.without_force do
          expect(foo.force?).to be_falsey
          expect(bar.force?).to be_falsey
        end

        expect(foo.force?).to be_falsey
        expect(bar.force?).to be_falsey
      end
    end

    context "when force is true" do
      let(:force) { true }

      it "force will be false inside the without_force block" do
        expect(foo.force?).to be_truthy
        expect(bar.force?).to be_truthy

        foo.without_force do
          expect(foo.force?).to be_falsey
          expect(bar.force?).to be_falsey
        end

        expect(foo.force?).to be_truthy
        expect(bar.force?).to be_truthy
      end
    end
  end
end
