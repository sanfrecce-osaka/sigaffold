# frozen_string_literal: true

require "fileutils"
require "tmpdir"

RSpec.describe Sigaffold::AppDetector do
  describe ".detect" do
    subject(:result) { described_class.detect(path) }

    context "when .gemspec exists" do
      let(:path) { Dir.mktmpdir }

      before { FileUtils.touch(File.join(path, "my_gem.gemspec")) }
      after { FileUtils.rm_rf(path) }

      it "returns :gem" do
        expect(result).to eq(:gem)
      end
    end

    context "when config/application.rb contains Rails::Application" do
      let(:path) { Dir.mktmpdir }

      before do
        FileUtils.mkdir_p(File.join(path, "config"))
        File.write(File.join(path, "config", "application.rb"), <<~RUBY)
          require_relative "boot"
          require "rails/all"

          module MyApp
            class Application < Rails::Application
            end
          end
        RUBY
      end
      after { FileUtils.rm_rf(path) }

      it "returns :rails" do
        expect(result).to eq(:rails)
      end
    end

    context "when config/application.rb exists but does not contain Rails::Application" do
      let(:path) { Dir.mktmpdir }

      before do
        FileUtils.mkdir_p(File.join(path, "config"))
        File.write(File.join(path, "config", "application.rb"), "# just a config file\n")
      end
      after { FileUtils.rm_rf(path) }

      it "returns :other" do
        expect(result).to eq(:other)
      end
    end

    context "when neither .gemspec nor config/application.rb exists" do
      let(:path) { Dir.mktmpdir }

      after { FileUtils.rm_rf(path) }

      it "returns :other" do
        expect(result).to eq(:other)
      end
    end

    context "when both .gemspec and config/application.rb with Rails::Application exist" do
      let(:path) { Dir.mktmpdir }

      before do
        FileUtils.touch(File.join(path, "my_gem.gemspec"))
        FileUtils.mkdir_p(File.join(path, "config"))
        File.write(File.join(path, "config", "application.rb"), <<~RUBY)
          class Application < Rails::Application; end
        RUBY
      end
      after { FileUtils.rm_rf(path) }

      it "prefers :gem over :rails" do
        expect(result).to eq(:gem)
      end
    end
  end
end
