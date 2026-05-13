# frozen_string_literal: true

RSpec.describe Sigaffold::RbsTraceIntroducer, type: :aruba do
  subject(:introducer) { described_class.new(path: expand_path("."), confirmer: confirmer) }

  let(:confirmer) { ->(_cmd) { "n" } }
  let(:prepare_files) { nil }

  before do
    prepare_files
    allow(introducer).to receive(:execute)
  end

  describe "#run" do
    describe "bundle add rbs-inline" do
      context "when app is not Rails" do
        context "when confirmer approves" do
          let(:confirmer) { ->(_cmd) { "y" } }

          it "runs bundle add rbs-inline without group" do
            introducer.run
            expect(introducer).to have_received(:execute).with("bundle add rbs-inline --skip-install --require false")
          end
        end

        context "when confirmer denies" do
          it "does not run bundle add rbs-inline" do
            introducer.run
            expect(introducer).not_to have_received(:execute).with("bundle add rbs-inline --skip-install --require false")
          end
        end
      end

      context "when app is Rails" do
        let(:prepare_files) do
          write_file("config/application.rb", "class Application < Rails::Application; end\n")
        end

        context "when confirmer approves" do
          let(:confirmer) { ->(_cmd) { "y" } }

          it "runs bundle add rbs-inline with development and test groups" do
            introducer.run
            expect(introducer).to have_received(:execute).with("bundle add rbs-inline --skip-install --group development,test --require false")
          end
        end

        context "when confirmer denies" do
          it "does not run bundle add rbs-inline" do
            introducer.run
            expect(introducer).not_to have_received(:execute).with("bundle add rbs-inline --skip-install --group development,test --require false")
          end
        end
      end
    end

    describe "bundle add rbs-trace" do
      context "when app is not Rails" do
        context "when confirmer approves" do
          let(:confirmer) { ->(_cmd) { "y" } }

          it "runs bundle add rbs-trace without group" do
            introducer.run
            expect(introducer).to have_received(:execute).with("bundle add rbs-trace --skip-install")
          end
        end

        context "when confirmer denies" do
          it "does not run bundle add rbs-trace" do
            introducer.run
            expect(introducer).not_to have_received(:execute).with("bundle add rbs-trace --skip-install")
          end
        end
      end

      context "when app is Rails" do
        let(:prepare_files) do
          write_file("config/application.rb", "class Application < Rails::Application; end\n")
        end

        context "when confirmer approves" do
          let(:confirmer) { ->(_cmd) { "y" } }

          it "runs bundle add rbs-trace with test group only" do
            introducer.run
            expect(introducer).to have_received(:execute).with("bundle add rbs-trace --skip-install --group test")
          end
        end

        context "when confirmer denies" do
          it "does not run bundle add rbs-trace" do
            introducer.run
            expect(introducer).not_to have_received(:execute).with("bundle add rbs-trace --skip-install --group test")
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
  end
end
