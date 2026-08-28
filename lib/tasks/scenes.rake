namespace :scenes do
  desc "Generate embeddings for any scene missing one (safe to re-run)"
  task embed_missing: :environment do
    pending = Scene.where(embedding: nil)
    puts "#{pending.count} scene(s) missing an embedding."

    ok = 0
    failed = []

    pending.find_each do |scene|
      scene.generate_embedding!
      ok += 1
      print "."
    rescue StandardError => e
      failed << "Scene ##{scene.id} (#{scene.setting}/#{scene.level}): #{e.class}: #{e.message}"
    end

    puts "\nEmbedded #{ok}, failed #{failed.size}."
    failed.each { |line| puts "  ! #{line}" }
    puts "Embedded: #{Scene.where.not(embedding: nil).count}/#{Scene.count}"
  end
end
