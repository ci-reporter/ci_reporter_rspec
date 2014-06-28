require File.dirname(__FILE__) + "/../../spec_helper.rb"
require 'ci/reporter/rspec'
require 'stringio'

describe "The RSpec reporter" do
  before(:each) do
    @error = double("error")
    @error.stub(:expectation_not_met?).and_return(false)
    @error.stub(:pending_fixed?).and_return(false)
    @error.stub(:exception).and_return(StandardError.new)
    @report_mgr = double("report manager")
    @options = double("options")
    @args = [@options, StringIO.new("")]
    @args.shift unless defined?(::Spec) && ::Spec::VERSION::MAJOR == 1 && ::Spec::VERSION::MINOR >= 1
    @fmt = CI::Reporter::RSpec.new *@args
    @fmt.report_manager = @report_mgr
  end

  def rspec2_failing_example(exception_text)
    double('RSpec2.2 Example',
           :execution_result => {
             :exception => StandardError.new(exception_text)
           },
           :metadata => {
             :example_group => {
               :full_description => "description"
             }
           })
  end

  it "should create a test suite with one success, one failure, and one pending" do
    @report_mgr.should_receive(:write_report) do |suite|
      suite.testcases.length.should == 3
      suite.testcases[0].should_not be_failure
      suite.testcases[0].should_not be_error
      suite.testcases[1].should be_error
      suite.testcases[2].name.should =~ /\(PENDING\)/
    end

    example_group = double "example group"
    example_group.stub(:description).and_return "A context"

    @fmt.start(3)
    @fmt.example_group_started(example_group)
    @fmt.example_started("should pass")
    @fmt.example_passed("should pass")
    @fmt.example_started("should fail")
    @fmt.example_failed(rspec2_failing_example("should fail"), 1, @error)
    @fmt.example_started("should be pending")
    @fmt.example_pending("A context", "should be pending", "Not Yet Implemented")
    @fmt.start_dump
    @fmt.dump_summary(0.1, 3, 1, 1)
    @fmt.dump_pending
    @fmt.close
  end

  it "should use the example #description method when available" do
    group = double "example group"
    group.stub(:description).and_return "group description"
    example = double "example"
    example.stub(:description).and_return "should do something"

    @report_mgr.should_receive(:write_report) do |suite|
      suite.testcases.last.name.should == "should do something"
    end

    @fmt.start(2)
    @fmt.example_group_started(group)
    @fmt.example_started(example)
    @fmt.example_passed(example)
    @fmt.dump_summary(0.1, 1, 0, 0)
  end

  it "should create a test suite with failure in before(:all)" do
    example_group = double "example group"
    example_group.stub(:description).and_return "A context"

    @report_mgr.should_receive(:write_report)

    @fmt.start(2)
    @fmt.example_group_started(example_group)
    @fmt.example_failed(rspec2_failing_example("should fail"), 1, @error)
    @fmt.dump_summary(0.1, 1, 0, 0)
  end

  describe 'RSpec2Failure' do
    before(:each) do
      @formatter = CI::Reporter::RSpec.new
      @rspec20_example = double('RSpec2.0 Example',
                              :execution_result => {:exception_encountered => StandardError.new('rspec2.0 ftw')},
                              :metadata => {})

      @rspec22_example = rspec2_failing_example('rspec2.2 ftw')
    end

    it 'should handle rspec (< 2.2) execution results' do
      failure = CI::Reporter::RSpec2Failure.new(@rspec20_example, @formatter)
      failure.name.should_not be_nil
      failure.message.should == 'rspec2.0 ftw'
      failure.location.should_not be_nil
    end
    it 'should handle rspec (>= 2.2) execution results' do
      failure = CI::Reporter::RSpec2Failure.new(@rspec22_example, @formatter)
      failure.name.should_not be_nil
      failure.message.should == 'rspec2.2 ftw'
      failure.location.should_not be_nil
    end
  end
end
