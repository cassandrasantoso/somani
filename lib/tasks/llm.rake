require "json"

namespace :llm do
  desc "Summarize LLM usage and estimated cost by day"
  task usage: :environment do
    window = 30.days.ago.beginning_of_day..Time.current

    scope = LlmCall.where(created_at: window)
    puts "LLM usage, last 30 days\n\n"

    scope.group("DATE(created_at)").order("DATE(created_at) DESC").count.each do |day, calls|
      day_scope = LlmCall.where("created_at >= ? AND created_at < ?", day.to_time, day.to_time + 1.day)
      tokens = day_scope.sum(:total_tokens)
      cost = day_scope.sum(&:estimated_cost)

      puts format("%s  %4d calls  %9d tokens  $%.4f", day, calls, tokens.to_i, cost)
    end

    puts "\nBy model and operation:"
    scope.group(:model, :operation).order(:model, :operation).count.each do |(model, operation), calls|
      puts format("  %-24s %-14s %6d calls", model, operation, calls)
    end

    puts format("\nestimated 30-day cost: $%.2f", scope.sum(&:estimated_cost))
  end
end
