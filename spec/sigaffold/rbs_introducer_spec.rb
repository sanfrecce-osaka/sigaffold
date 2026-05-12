# frozen_string_literal: true

RSpec.describe Sigaffold::RbsIntroducer, type: :aruba do
  subject(:introducer) { described_class.new(path: expand_path("."), confirmer: confirmer) }

  let(:confirmer) { ->(_cmd) { "n" } }
  let(:prepare_files) { nil }

  before do
    prepare_files
    allow(introducer).to receive(:execute)
  end

  describe "#run" do
    describe "bundle add rbs" do
      context "when app is not Rails" do
        context "when confirmer approves" do
          let(:confirmer) { ->(_cmd) { "y" } }

          it "runs bundle add rbs without group" do
            introducer.run
            expect(introducer).to have_received(:execute).with("bundle add rbs --skip-install")
          end
        end

        context "when confirmer denies" do
          it "does not run bundle add rbs" do
            introducer.run
            expect(introducer).not_to have_received(:execute).with("bundle add rbs --skip-install")
          end
        end
      end

      context "when app is Rails" do
        let(:prepare_files) do
          write_file("config/application.rb", "class Application < Rails::Application; end\n")
        end

        context "when confirmer approves" do
          let(:confirmer) { ->(_cmd) { "y" } }

          it "runs bundle add rbs with development and test groups" do
            introducer.run
            expect(introducer).to have_received(:execute).with("bundle add rbs --skip-install --group development,test")
          end
        end

        context "when confirmer denies" do
          it "does not run bundle add rbs" do
            introducer.run
            expect(introducer).not_to have_received(:execute).with("bundle add rbs --skip-install --group development,test")
          end
        end
      end
    end

    describe "bundle install" do
      context "when confirmer approves" do
        let(:confirmer) { ->(_cmd) { "y" } }

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
        let(:confirmer) { ->(_cmd) { "y" } }

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
          expect(".gitignore").to have_file_content(include(".gem_rbs_collection"))
        end
      end

      context "when .gitignore exists but does not contain .gem_rbs_collection" do
        before { write_file(".gitignore", "*.log\n") }

        it "appends .gem_rbs_collection without removing existing entries" do
          introducer.run
          expect(".gitignore").to have_file_content(include(".gem_rbs_collection"))
          expect(".gitignore").to have_file_content(include("*.log"))
        end
      end

      context "when .gitignore already contains .gem_rbs_collection" do
        before { write_file(".gitignore", ".gem_rbs_collection\n") }

        it "does not duplicate the entry" do
          introducer.run
          count = read(".gitignore").count { |line| line.strip == ".gem_rbs_collection" }
          expect(count).to eq(1)
        end
      end
    end

    describe "bundle exec rbs collection install" do
      context "when confirmer approves" do
        let(:confirmer) { ->(_cmd) { "y" } }

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
