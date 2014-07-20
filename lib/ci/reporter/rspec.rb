require 'ci/reporter/core'
require 'rspec/core/formatters/base_formatter'

module CI
  module Reporter
    # Wrapper around a <code>RSpec</code> error or failure to be used by the test suite to interpret results.
    class RSpec3Failure
      attr_reader :exception

      def initialize(notification, formatter)
        @formatter = formatter
        @notification = notification
        @exception = @notification.exception
      end

      def name
        @exception.class.name
      end

      def message
        @exception.message
      end

      def failure?
        exception.is_a?(::RSpec::Expectations::ExpectationNotMetError)
      end

      def error?
        !failure?
      end

      def location
        output = []
        output.push "#{exception.class.name << ":"}" unless exception.class.name =~ /RSpec/
        output.push @exception.message

        [@notification.formatted_backtrace].flatten.each do |backtrace_info|
          backtrace_info.lines.each do |line|
            output.push "     #{line}"
          end
        end
        output.join "\n"
      end
    end

    # Custom +RSpec+ formatter used to hook into the spec runs and capture results.
    class RSpecFormatter < ::RSpec::Core::Formatters::BaseFormatter
      ::RSpec::Core::Formatters.register self, :example_group_started, :example_started, :example_failed, :example_passed, :example_pending, :dump_summary

      attr_accessor :report_manager
      def initialize(*args)
        @report_manager = ReportManager.new("spec")
        @suite = nil
      end

      def example_group_started(group_notification)
        new_suite(description_for(group_notification))
      end

      def example_started(_example_notification)
        spec = TestCase.new
        @suite.testcases << spec
        spec.start
      end

      def example_failed(example_notification)
        # In case we fail in before(:all)
        example_started(example_notification) if @suite.testcases.empty?

        failure = RSpec3Failure.new(example_notification, self)

        spec = @suite.testcases.last
        spec.finish
        spec.name = description_for(example_notification)
        spec.failures << failure
      end

      def example_passed(example_notification)
        spec = @suite.testcases.last
        spec.finish
        spec.name = description_for(example_notification)
      end

      def example_pending(example_notification)
        name = description_for(example_notification)
        spec = @suite.testcases.last
        spec.finish
        spec.name = "#{name} (PENDING)"
        spec.skipped = true
      end

      def dump_summary(_summary_notification)
        write_report
      end

      private
      def description_for(notification)
        if notification.respond_to?(:example)
          notification.example.full_description
        elsif notification.respond_to?(:group)
          notification.group.description
        else
          "UNKNOWN"
        end
      end

      def write_report
        if @suite
          @suite.finish
          @report_manager.write_report(@suite)
        end
      end

      def new_suite(name)
        write_report if @suite
        @suite = TestSuite.new name
        @suite.start
      end
    end
  end
end
