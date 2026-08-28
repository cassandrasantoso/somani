class GenerateTitleJob < ApplicationJob
  queue_as :default

  retry_on Faraday::TooManyRequestsError, wait: :polynomially_longer, attempts: 5

  def perform(adventure)
    adventure.generate_title
  end
end
