require File.dirname(__FILE__) + "/../../spec_helper"
require 'ci/reporter/rspec'
require 'stringio'

describe "The RSpec reporter" do
  let(:report_manager) { double(CI::Reporter::ReportManager) }
  before do
    allow(CI::Reporter::ReportManager).to receive(:new).and_return(report_manager)
  end

  it "should create a test suite with one success, one failure, and one pending" do
    expect(report_manager).to receive(:write_report) do |suite|
      expect(suite.testcases.length).to eq 4
      expect(suite.testcases[0]).not_to be_failure
      expect(suite.testcases[0]).not_to be_error
      expect(suite.testcases[1]).to be_failure
      expect(suite.testcases[2]).to be_error
      expect(suite.testcases[3].name).to match /\(PENDING\)/
    end

    run_dummy_tests do
      it 'should pass' do
        expect(1).to eq 1
      end

      it 'should fail' do
        expect(1).to eq 0
      end

      it 'should be error' do
        raise 'error'
      end

      it 'should be pending'
    end
  end

  it "should use the example #description method when available" do
    expect(report_manager).to receive(:write_report) do |suite|
      expect(suite.testcases.last.name).to eq " should do something"
    end

    run_dummy_tests do
      it 'should do something' do
      end
    end
  end

  it "should create a test suite with failure in before(:all)" do
    expect(report_manager).to receive(:write_report) do |suite|
      expect(suite.testcases.last.name).to eq " should do something"
      expect(suite.testcases.last).to be_error
    end

    run_dummy_tests do
      before(:all) do
        raise 'error in before:all'
      end

      it 'should do something' do
      end
    end
  end

  def run_dummy_tests(&block)
    rspec_configuration = RSpec::Core::Configuration.new
     rspec_configuration.add_formatter(CI::Reporter::RSpecFormatter)

    root_example_group = Class.new(RSpec::Core::ExampleGroup) do
      def self.description
        'A context'
      end

      def self.metadata
        RSpec::Core::Metadata::ExampleGroupHash.create(superclass_metadata, RSpec::Core::Metadata.build_hash_from([{}]))
      end

      def self.filtered_examples
        examples
      end
    end
    root_example_group.class_eval(&block)
    example_groups = [root_example_group]

    rspec_configuration.reporter.report(RSpec.world.example_count(example_groups)) do |reporter|
      begin
        hook_context = RSpec::Core::SuiteHookContext.new
        rspec_configuration.hooks.run(:before, :suite, hook_context)
        example_groups.map { |g| g.run(reporter) }.all?
      ensure
        rspec_configuration.hooks.run(:after, :suite, hook_context)
      end
    end
  end
end
