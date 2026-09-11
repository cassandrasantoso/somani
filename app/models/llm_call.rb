class LlmCall < ApplicationRecord
  # Published USD list prices per million tokens. Estimates only — enough to
  # answer "what did today cost" without waiting on an invoice.
  PRICES_PER_MTOK = {
    "gemini-3.1-flash-lite" => { input: 0.25, output: 1.50 },
    "gemini-2.5-flash" => { input: 0.30, output: 2.50 },
    "gemini-2.5-flash-lite" => { input: 0.10, output: 0.40 },
    "gemini-2.5-pro" => { input: 1.25, output: 10.00 },
    "gemini-embedding-001" => { input: 0.10, output: 0.0 }
  }.freeze
  FALLBACK_PRICE = { input: 0.25, output: 1.50 }.freeze

  def estimated_cost
    price = PRICES_PER_MTOK.fetch(model, FALLBACK_PRICE)
    ((prompt_tokens.to_i * price[:input]) + (completion_tokens.to_i * price[:output])) / 1_000_000.0
  end

  def self.estimated_cost_between(range)
    where(created_at: range).sum(&:estimated_cost)
  end
end
