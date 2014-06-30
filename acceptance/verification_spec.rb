require 'rexml/document'
require 'ci/reporter/test_utils/accessor'
require 'ci/reporter/test_utils/shared_examples'

REPORTS_DIR = File.dirname(__FILE__) + '/reports'

shared_examples "assertions are not tracked" do
  describe "the assertion count" do
    subject { result.assertions_count }
    it { should eql 0 }
  end
end

describe "RSpec acceptance" do
  include CI::Reporter::TestUtils::SharedExamples
  Accessor = CI::Reporter::TestUtils::Accessor

  let(:failing_report_path) { File.join(REPORTS_DIR, 'SPEC-RSpec-example.xml') }
  let(:nested_report_path)  { File.join(REPORTS_DIR, 'SPEC-RSpec-example-nested.xml') }

  context "the failing test" do
    subject(:result) { Accessor.new(load_xml_result(failing_report_path)) }

    it { should have(0).errors }
    it { should have(1).failures }
    it { should have(3).testcases }

    describe "the failure" do
      subject(:failure) { result.failures.first }
      it "indicates the type" do
        failure.attributes['type'].should =~ /ExpectationNotMetError/
      end
    end

    it_behaves_like "a report with consistent attribute counts"
    it_behaves_like "assertions are not tracked"
    it_behaves_like "nothing was output"
  end

  context "with a nested context" do
    subject(:result) { Accessor.new(load_xml_result(nested_report_path)) }

    it { should have(0).errors }
    it { should have(0).failures }
    it { should have(1).testcases }

    it_behaves_like "a report with consistent attribute counts"
    it_behaves_like "assertions are not tracked"
    it_behaves_like "nothing was output"
  end

  def load_xml_result(path)
    File.open(path) do |f|
      REXML::Document.new(f)
    end
  end
end
