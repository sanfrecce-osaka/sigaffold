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

    describe "spec/spec_helper.rb" do
      context "when spec/spec_helper.rb does not exist" do
        it "does not raise an error" do
          expect { introducer.run }.not_to raise_error
        end
      end

      context "when spec/spec_helper.rb contains RSpec.configure block" do
        before { write_file("spec/spec_helper.rb", "RSpec.configure do |config|\nend\n") }

        it "adds rbs-trace configuration inside the block" do
          introducer.run
          expected = <<~'EXPECTED'.chomp
            RSpec.configure do |config|
              if ENV.fetch('TRACE', '') in /\A.+/ => path_glob_or_flag
                require "rbs/trace"
                options = (path_glob_or_flag in %r{\A/.+} => path_glob) ? { paths: Dir.glob("#{Dir.pwd}#{path_glob}") } : {} # rubocop:disable Style/RedundantParentheses
                trace = RBS::Trace.new(**options)
                trace.add_generics_size!(
                  'CSV::Table' => 1, 'ActiveSupport::HashWithIndifferentAccess' => 2, 'ActionController::ParameterMissing' => 2
                )

                config.before(:suite) { trace.enable }
                config.after(:suite) do
                  trace.disable
                  trace.save_comments(:rbs_colon)
                  out_dir = "tmp/sig-#{ENV.fetch('TEST_ENV_NUMBER'}', '0')}"
                  warn "[RBS_TRACE] saving to #{out_dir}"
                  trace.save_files(out_dir:)
                  warn '[RBS_TRACE] saved'
                end
              end
            end
          EXPECTED
          expect(read("spec/spec_helper.rb").join("\n")).to eq(expected)
        end
      end

      context "when spec/spec_helper.rb contains RSpec.configure block with existing configuration" do
        before { write_file("spec/spec_helper.rb", "RSpec.configure do |config|\n  config.order = :random\nend\n") }

        it "appends rbs-trace configuration after existing entries" do
          introducer.run
          expected = <<~'EXPECTED'.chomp
            RSpec.configure do |config|
              config.order = :random

              if ENV.fetch('TRACE', '') in /\A.+/ => path_glob_or_flag
                require "rbs/trace"
                options = (path_glob_or_flag in %r{\A/.+} => path_glob) ? { paths: Dir.glob("#{Dir.pwd}#{path_glob}") } : {} # rubocop:disable Style/RedundantParentheses
                trace = RBS::Trace.new(**options)
                trace.add_generics_size!(
                  'CSV::Table' => 1, 'ActiveSupport::HashWithIndifferentAccess' => 2, 'ActionController::ParameterMissing' => 2
                )

                config.before(:suite) { trace.enable }
                config.after(:suite) do
                  trace.disable
                  trace.save_comments(:rbs_colon)
                  out_dir = "tmp/sig-#{ENV.fetch('TEST_ENV_NUMBER'}', '0')}"
                  warn "[RBS_TRACE] saving to #{out_dir}"
                  trace.save_files(out_dir:)
                  warn '[RBS_TRACE] saved'
                end
              end
            end
          EXPECTED
          expect(read("spec/spec_helper.rb").join("\n")).to eq(expected)
        end
      end

      context "when spec/spec_helper.rb already contains rbs-trace configuration" do
        before { write_file("spec/spec_helper.rb", "RSpec.configure do |config|\n  RBS::Trace.new\nend\n") }

        it "does not duplicate the configuration" do
          introducer.run
          count = read("spec/spec_helper.rb").count { |line| line.include?("RBS::Trace") }
          expect(count).to eq(1)
        end
      end
    end

    context "when app is Rails" do
      let(:prepare_files) do
        write_file("config/application.rb", "class Application < Rails::Application; end\n")
      end

      describe "spec/rails_helper.rb" do
        context "when spec/rails_helper.rb contains RSpec.configure block" do
          before { write_file("spec/rails_helper.rb", "RSpec.configure do |config|\nend\n") }

          it "adds rbs-trace configuration into spec/rails_helper.rb" do
            introducer.run
            expected = <<~'EXPECTED'.chomp
              RSpec.configure do |config|
                if ENV.fetch('TRACE', '') in /\A.+/ => path_glob_or_flag
                  require "rbs/trace"
                  options = (path_glob_or_flag in %r{\A/.+} => path_glob) ? { paths: Dir.glob("#{Dir.pwd}#{path_glob}") } : {} # rubocop:disable Style/RedundantParentheses
                  trace = RBS::Trace.new(**options)
                  trace.add_generics_size!(
                    'CSV::Table' => 1, 'ActiveSupport::HashWithIndifferentAccess' => 2, 'ActionController::ParameterMissing' => 2
                  )

                  config.before(:suite) { trace.enable }
                  config.after(:suite) do
                    trace.disable
                    trace.save_comments(:rbs_colon)
                    out_dir = "tmp/sig-#{ENV.fetch('TEST_ENV_NUMBER'}', '0')}"
                    warn "[RBS_TRACE] saving to #{out_dir}"
                    trace.save_files(out_dir:)
                    warn '[RBS_TRACE] saved'
                  end
                end
              end
            EXPECTED
            expect(read("spec/rails_helper.rb").join("\n")).to eq(expected)
          end
        end

        context "when spec/rails_helper.rb contains RSpec.configure block with existing configuration" do
          before { write_file("spec/rails_helper.rb", "RSpec.configure do |config|\n  config.order = :random\nend\n") }

          it "appends rbs-trace configuration after existing entries" do
            introducer.run
            expected = <<~'EXPECTED'.chomp
              RSpec.configure do |config|
                config.order = :random

                if ENV.fetch('TRACE', '') in /\A.+/ => path_glob_or_flag
                  require "rbs/trace"
                  options = (path_glob_or_flag in %r{\A/.+} => path_glob) ? { paths: Dir.glob("#{Dir.pwd}#{path_glob}") } : {} # rubocop:disable Style/RedundantParentheses
                  trace = RBS::Trace.new(**options)
                  trace.add_generics_size!(
                    'CSV::Table' => 1, 'ActiveSupport::HashWithIndifferentAccess' => 2, 'ActionController::ParameterMissing' => 2
                  )

                  config.before(:suite) { trace.enable }
                  config.after(:suite) do
                    trace.disable
                    trace.save_comments(:rbs_colon)
                    out_dir = "tmp/sig-#{ENV.fetch('TEST_ENV_NUMBER'}', '0')}"
                    warn "[RBS_TRACE] saving to #{out_dir}"
                    trace.save_files(out_dir:)
                    warn '[RBS_TRACE] saved'
                  end
                end
              end
            EXPECTED
            expect(read("spec/rails_helper.rb").join("\n")).to eq(expected)
          end
        end
      end
    end
  end
end
