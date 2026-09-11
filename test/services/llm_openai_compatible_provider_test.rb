require "test_helper"

class LlmOpenaiCompatibleProviderTest < ActiveSupport::TestCase
  test "parses SSE lines into deltas, usage and the terminator" do
    delta, usage, done = Llm::OpenaiCompatibleProvider.parse_sse_line(
      'data: {"choices":[{"delta":{"content":"こん"}}]}'
    )
    assert_equal "こん", delta
    assert_equal({}, usage)
    assert_not done

    delta, usage, done = Llm::OpenaiCompatibleProvider.parse_sse_line(
      'data: {"choices":[],"usage":{"prompt_tokens":9,"total_tokens":11}}'
    )
    assert_nil delta
    assert_equal 9, usage[:prompt_tokens]
    assert_not done

    delta, _usage, done = Llm::OpenaiCompatibleProvider.parse_sse_line("data: [DONE]")
    assert_nil delta
    assert done

    delta, _usage, done = Llm::OpenaiCompatibleProvider.parse_sse_line(": keep-alive")
    assert_nil delta
    assert_not done
  end

  test "builds a chat completion and returns text with usage" do
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("/chat/completions") do |_env|
        [200, { "Content-Type" => "application/json" },
         { "choices" => [{ "message" => { "content" => "こんにちは" } }],
           "usage" => { "prompt_tokens" => 25, "completion_tokens" => 4,
                        "total_tokens" => 29, "prompt_tokens_details" => { "cached_tokens" => 10 } } }]
      end
    end

    original_key = ENV["OPENAI_API_KEY"]
    ENV["OPENAI_API_KEY"] = "test-key"

    stub_connection(stubs) do
      result = Llm::OpenaiCompatibleProvider.generate_text("Say hello", system_instruction: "Stay kind.")

      assert_equal "こんにちは", result.text
      assert_equal 25, result.usage[:prompt_tokens]
      assert_equal 10, result.usage[:cached_tokens]
    end
  ensure
    ENV["OPENAI_API_KEY"] = original_key
  end

  test "maps image parts to base64 data URLs" do
    content = Llm::OpenaiCompatibleProvider.send(:parts_to_content,
                                                  [{ text: "What is in this image?" },
                                                   { inline_data: { mime_type: "image/png", data: "abc123" } }])

    assert_equal({ type: "text", text: "What is in this image?" }, content.first)
    assert_equal({ type: "image_url", image_url: { url: "data:image/png;base64,abc123" } }, content.second)
  end

  test "rejects audio parts with a clear error" do
    assert_raises(ArgumentError) do
      Llm::OpenaiCompatibleProvider.send(:parts_to_content,
                                         [{ inline_data: { mime_type: "audio/mp3", data: "xyz" } }])
    end
  end

  private

  def stub_connection(stubs)
    original = Llm::OpenaiCompatibleProvider.method(:connection)
    test_connection = Faraday.new do |faraday|
      faraday.request :json
      faraday.response :json
      faraday.adapter :test, stubs
    end

    Llm::OpenaiCompatibleProvider.define_singleton_method(:connection) { test_connection }
    yield
  ensure
    Llm::OpenaiCompatibleProvider.singleton_class.send(:define_method, :connection) do |*args, **kwargs, &block|
      original.call(*args, **kwargs, &block)
    end
  end
end
