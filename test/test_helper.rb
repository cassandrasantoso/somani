ENV["RAILS_ENV"] ||= "test"
# Tests stub Gemini.new itself (see AdventuresControllerTest#stub_gemini), so
# no request ever leaves the machine — but GeminiClient still reads the key
# while building the call, and CI has no .env to read it from.
ENV["GEMINI_API_KEY"] ||= "test-key"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
