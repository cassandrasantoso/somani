class AddCachedTokensToLlmCalls < ActiveRecord::Migration[8.1]
  def change
    add_column :llm_calls, :cached_tokens, :integer
  end
end
