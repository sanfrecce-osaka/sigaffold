# frozen_string_literal: true

RSpec.describe Sigaffold::ReplTypeCompletorIntroducer, type: :aruba do
  subject(:introducer) { described_class.new(path: expand_path("."), confirmer: confirmer) }

  let(:confirmer) { ->(_cmd) { "n" } }
  let(:prepare_files) { nil }

  before do
    prepare_files
    allow(introducer).to receive(:execute)
  end

  describe "#run" do
    describe "bundle add repl_type_completor" do
      context "when app is not Rails" do
        context "when confirmer approves" do
          let(:confirmer) { ->(_cmd) { "y" } }

          it "runs bundle add repl_type_completor without group" do
            introducer.run
            expect(introducer).to have_received(:execute).with("bundle add repl_type_completor --skip-install")
          end
        end

        context "when confirmer denies" do
          it "does not run bundle add repl_type_completor" do
            introducer.run
            expect(introducer).not_to have_received(:execute).with("bundle add repl_type_completor --skip-install")
          end
        end
      end

      context "when app is Rails" do
        let(:prepare_files) do
          write_file("config/application.rb", "class Application < Rails::Application; end\n")
        end

        context "when confirmer approves" do
          let(:confirmer) { ->(_cmd) { "y" } }

          it "runs bundle add repl_type_completor with development and test groups" do
            introducer.run
            expect(introducer).to have_received(:execute).with("bundle add repl_type_completor --skip-install --group development,test")
          end
        end

        context "when confirmer denies" do
          it "does not run bundle add repl_type_completor" do
            introducer.run
            expect(introducer).not_to have_received(:execute).with("bundle add repl_type_completor --skip-install --group development,test")
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

    describe ".irbrc" do
      context "when .irbrc does not exist" do
        it "creates .irbrc containing IRB.conf[:COMPLETOR] = :type" do
          introducer.run
          expect(".irbrc").to have_file_content(include("IRB.conf[:COMPLETOR] = :type"))
        end
      end

      context "when .irbrc exists but does not contain IRB.conf[:COMPLETOR] = :type" do
        before { write_file(".irbrc", "IRB.conf[:PROMPT_MODE] = :SIMPLE\n") }

        it "appends IRB.conf[:COMPLETOR] = :type without removing existing entries" do
          introducer.run
          expect(".irbrc").to have_file_content(include("IRB.conf[:COMPLETOR] = :type"))
          expect(".irbrc").to have_file_content(include("IRB.conf[:PROMPT_MODE] = :SIMPLE"))
        end
      end

      context "when .irbrc already contains IRB.conf[:COMPLETOR] = :type" do
        before { write_file(".irbrc", "IRB.conf[:COMPLETOR] = :type\n") }

        it "does not duplicate the entry" do
          introducer.run
          count = read(".irbrc").count { |line| line.strip == "IRB.conf[:COMPLETOR] = :type" }
          expect(count).to eq(1)
        end
      end
    end
  end
end
