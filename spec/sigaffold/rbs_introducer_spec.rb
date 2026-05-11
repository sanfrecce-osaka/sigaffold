# frozen_string_literal: true

require "fileutils"
require "tmpdir"

RSpec.describe Sigaffold::RbsIntroducer do
  subject(:introducer) { described_class.new(path: path, confirmer: confirmer) }

  let(:path) { Dir.mktmpdir }
  let(:confirmer) { ->(_cmd) { false } }
  let(:prepare_files) { nil }

  before do
    prepare_files
    allow(introducer).to receive(:execute)
  end
  after { FileUtils.rm_rf(path) }

  describe "#run" do
    describe "bundle add rbs" do
      context "when app is not Rails" do
        it "runs bundle add rbs without group" do
          introducer.run
          expect(introducer).to have_received(:execute).with("bundle add rbs --skip-install")
        end
      end

      context "when app is Rails" do
        let(:prepare_files) do
          FileUtils.mkdir_p(File.join(path, "config"))
          File.write(File.join(path, "config", "application.rb"), "class Application < Rails::Application; end\n")
        end

        it "runs bundle add rbs with development and test groups" do
          introducer.run
          expect(introducer).to have_received(:execute).with("bundle add rbs --skip-install --group development,test")
        end
      end
    end

    describe "bundle install" do
      context "when confirmer approves" do
        let(:confirmer) { ->(cmd) { cmd == "bundle install" } }

        it "runs bundle install" do
          introducer.run
          expect(introducer).to have_received(:execute).with("bundle install")
        end
      end

      context "when confirmer denies" do
        it "does not run bundle install" do
          introducer.run
          expect(introducer).not_to have_received(:execute).with("bundle install")
        end
      end
    end

    describe "bundle exec rbs collection init" do
      context "when confirmer approves" do
        let(:confirmer) { ->(cmd) { cmd == "bundle exec rbs collection init" } }

        it "runs rbs collection init" do
          introducer.run
          expect(introducer).to have_received(:execute).with("bundle exec rbs collection init")
        end
      end

      context "when confirmer denies" do
        it "does not run rbs collection init" do
          introducer.run
          expect(introducer).not_to have_received(:execute).with("bundle exec rbs collection init")
        end
      end
    end

    describe ".gitignore" do
      context "when .gitignore does not exist" do
        it "creates .gitignore containing .gem_rbs_collection" do
          introducer.run
          expect(File.read(File.join(path, ".gitignore"))).to include(".gem_rbs_collection")
        end
      end

      context "when .gitignore exists but does not contain .gem_rbs_collection" do
        before { File.write(File.join(path, ".gitignore"), "*.log\n") }

        it "appends .gem_rbs_collection without removing existing entries" do
          introducer.run
          content = File.read(File.join(path, ".gitignore"))
          expect(content).to include(".gem_rbs_collection")
          expect(content).to include("*.log")
        end
      end

      context "when .gitignore already contains .gem_rbs_collection" do
        before { File.write(File.join(path, ".gitignore"), ".gem_rbs_collection\n") }

        it "does not duplicate the entry" do
          introducer.run
          count = File.read(File.join(path, ".gitignore")).scan(".gem_rbs_collection").length
          expect(count).to eq(1)
        end
      end
    end

    describe "bundle exec rbs collection install" do
      context "when confirmer approves" do
        let(:confirmer) { ->(cmd) { cmd == "bundle exec rbs collection install" } }

        it "runs rbs collection install" do
          introducer.run
          expect(introducer).to have_received(:execute).with("bundle exec rbs collection install")
        end
      end

      context "when confirmer denies" do
        it "does not run rbs collection install" do
          introducer.run
          expect(introducer).not_to have_received(:execute).with("bundle exec rbs collection install")
        end
      end
    end
  end
end
