# frozen_string_literal: true

RSpec.describe Sigaffold::AppDetector, type: :aruba do
  describe ".detect" do
    subject(:result) { described_class.detect(expand_path(".")) }

    context "when .gemspec exists" do
      before { touch("my_gem.gemspec") }

      it "returns :gem" do
        expect(result).to eq(:gem)
      end
    end

    context "when config/application.rb contains Rails::Application" do
      before do
        write_file("config/application.rb", <<~RUBY)
          require_relative "boot"
          require "rails/all"

          module MyApp
            class Application < Rails::Application
            end
          end
        RUBY
      end

      it "returns :rails" do
        expect(result).to eq(:rails)
      end
    end

    context "when config/application.rb exists but does not contain Rails::Application" do
      before { write_file("config/application.rb", "# just a config file\n") }

      it "returns :other" do
        expect(result).to eq(:other)
      end
    end

    context "when neither .gemspec nor config/application.rb exists" do
      it "returns :other" do
        expect(result).to eq(:other)
      end
    end

    context "when both .gemspec and config/application.rb with Rails::Application exist" do
      before do
        touch("my_gem.gemspec")
        write_file("config/application.rb", "class Application < Rails::Application; end\n")
      end

      it "prefers :gem over :rails" do
        expect(result).to eq(:gem)
      end
    end
  end
end
