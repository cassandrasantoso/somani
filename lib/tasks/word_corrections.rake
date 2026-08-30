namespace :word_corrections do
  desc "Rebuild the correction index from existing feedback jsonb"
  task rebuild: :environment do
    WordCorrection.delete_all

    Feedback.includes(message: { adventure: :upload }).find_each do |feedback|
      IndexWordCorrections.call(feedback)
    end

    puts "#{WordCorrection.count} corrections indexed " \
         "from #{Feedback.where.not(corrections: []).count} feedbacks"
  end
end
