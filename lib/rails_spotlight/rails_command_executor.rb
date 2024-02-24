# frozen_string_literal: true

module RailsSpotlight
  class RailsCommandExecutor
    def execute(command)
      output_stream = StringIO.new # Create a new StringIO object to capture output
      @result = nil
      @error = nil
      @syntax_error = false

      begin
        original_stdout = $stdout
        $stdout = output_stream
        @result = eval(command) # rubocop:disable Security/Eval
      rescue SyntaxError => e
        @error = e
        @syntax_error = true
      rescue => e # rubocop:disable Style/RescueStandardError
        @error = e
      ensure
        $stdout = original_stdout
      end

      @console = output_stream.string
      self
    rescue => e # rubocop:disable Style/RescueStandardError
      @error = e
    ensure
      self
    end

    attr_reader :result, :console, :error, :syntax_error

    def execution_successful?
      error.nil?
    end

    def result_as_json(inspect_types: false)
      if error
        {
          status: :error,
          syntax_error: syntax_error,
          error: error.respond_to?(:message) ? error.message : error.to_s,
          backtrace: error.respond_to?(:backtrace) ? error.backtrace : nil
        }
      else
        {
          status: :ok,
          inspect: result.inspect,
          raw: result,
          type: result.class.name,
          types: result_inspect_types(inspect_types, result),
          console: console
        }
      end
    end

    private

    def result_inspect_types(inspect_types, result)
      return {} unless inspect_types

      {
        root: result.class.name,
        items: result_types_items(result)
      }
    end

    def result_types_items(result)
      case result
      when Array
        # Create a hash with indices as keys and class names as values
        result.each_with_index.to_h { |element, index| [index.to_s, element.class.name] }
      when Hash
        # Create a hash with string keys and class names as values
        result.transform_keys(&:to_s).transform_values { |value| value.class.name }
      else
        # For non-collection types, there are no items
        {}
      end
    end
  end
end
