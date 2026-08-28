class GenerateSceneEmbeddingJob < ApplicationJob
  queue_as :default

  retry_on Faraday::TooManyRequestsError, wait: :polynomially_longer, attempts: 5

  def perform(scene)
    scene.generate_embedding!
  end
end
