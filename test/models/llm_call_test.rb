require "test_helper"

class LlmCallTest < ActiveSupport::TestCase
  test "records usage for every Llm call" do
    original_new = Gemini.method(:new)
    fake = Class.new do
      def generate_content(_payload)
        { "candidates" => [{ "content" => { "parts" => [{ "text" => "こんにちは" }] } }],
          "usageMetadata" => { "promptTokenCount" => 12, "candidatesTokenCount" => 5, "totalTokenCount" => 17 } }
      end
    end.new
    Gemini.define_singleton_method(:new) { |*_args, **_kwargs| fake }

    text = nil
    assert_difference "LlmCall.count", 1 do
      text = Llm.generate_text("Say hello")
    end

    assert_equal "こんにちは", text

    call = LlmCall.last
    assert_equal "gemini-3.1-flash-lite", call.model
    assert_equal "generate", call.operation
    assert_equal 12, call.prompt_tokens
    assert_equal 5, call.completion_tokens
    assert_not_nil call.duration_ms
  ensure
    Gemini.singleton_class.send(:define_method, :new) do |*args, **kwargs, &block|
      original_new.call(*args, **kwargs, &block)
    end
  end

  test "estimated_cost uses the model price table" do
    call = LlmCall.new(model: "gemini-2.5-flash", prompt_tokens: 1_000_000,
                       completion_tokens: 1_000_000)

    assert_in_delta 2.80, call.estimated_cost, 0.0001
  end

  test "unknown models fall back to the flash price" do
    call = LlmCall.new(model: "some-future-model", prompt_tokens: 1_000_000, completion_tokens: 0)

    assert_in_delta 0.25, call.estimated_cost, 0.0001
  end
end
