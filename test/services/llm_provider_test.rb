require "test_helper"

class LlmProviderTest < ActiveSupport::TestCase
  class FakeProvider
    class << self
      def resolve_model(model) = "fake-#{model || 'primary'}"

      def generate_text(_prompt, system_instruction: nil, parts: [], json: false, model: nil)
        Llm::Result.new(text: "fake reply", usage: { prompt_tokens: 10, completion_tokens: 2,
                                                     total_tokens: 12, cached_tokens: 4 })
      end
    end
  end

  def with_provider(name)
    original = ENV["LLM_PROVIDER"]
    ENV["LLM_PROVIDER"] = name
    yield
  ensure
    ENV["LLM_PROVIDER"] = original
  end

  test "dispatches to the configured provider and records usage with its model" do
    Llm.register_provider("fake", FakeProvider)

    with_provider("fake") do
      assert_difference "LlmCall.count", 1 do
        assert_equal "fake reply", Llm.generate_text("hello")
      end
    end

    call = LlmCall.last
    assert_equal "fake-primary", call.model
    assert_equal "generate", call.operation
    assert_equal 4, call.cached_tokens
  ensure
    Llm::PROVIDERS.delete("fake")
  end

  test "raises clearly for an unregistered provider" do
    with_provider("nope") do
      assert_raises(ArgumentError) { Llm.generate_text("hello") }
    end
  end

  test "embeddings always route to the Gemini provider" do
    Llm.register_provider("fake", FakeProvider)

    with_provider("fake") do
      original_new = Gemini.method(:new)
      fake_gemini = Class.new do
        def embed_content(_payload)
          { "embedding" => { "values" => [0.1, 0.2] },
            "usageMetadata" => { "promptTokenCount" => 3, "totalTokenCount" => 3 } }
        end
      end.new
      Gemini.define_singleton_method(:new) { |*_a, **_k| fake_gemini }

      assert_equal [0.1, 0.2], Llm.embed("テスト")

      assert_equal Llm::GeminiProvider::EMBED_MODEL, LlmCall.last.model
    ensure
      Gemini.singleton_class.send(:define_method, :new) do |*args, **kwargs, &block|
        original_new.call(*args, **kwargs, &block)
      end
    end
  ensure
    Llm::PROVIDERS.delete("fake")
  end
end
