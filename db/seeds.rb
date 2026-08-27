# db/seeds.rb
#
# Characters and scenes are keyed by their natural identity (name / setting)
# so re-running this script is a no-op for rows that already exist, instead
# of creating duplicates. Scene.destroy_all / Character.destroy_all below
# silently skip any row still referenced by an adventure (dependent:
# :restrict_with_error), so a plain create! there would pile up duplicates
# every time someone reseeds a dev database that already has adventures in it.
puts "Cleaning seed tables..."
Scene.destroy_all
Character.destroy_all
JlptEntry.destroy_all

puts "Creating characters..."
yuki = Character.find_or_create_by!(name: "Yuki") do |c|
  c.persona = "A friendly and professional news reporter in Tokyo. Speaks clear, natural Japanese and reports on current events, society, business, and culture. Explains difficult news vocabulary clearly, asks thoughtful follow-up questions, and is patient with language mistakes."
  c.voice = "ja-JP-NanamiNeural"
end

yuki.image.attach(
  io: File.open(Rails.root.join("db", "character_avatars", "news.png")),
  filename: "news.png",
  content_type: "image/png"
) unless yuki.image.attached?

takeshi = Character.find_or_create_by!(name: "Takeshi") do |c|
  c.persona = "A friendly coworker at a Tokyo company. Speaks natural, polite business Japanese and often talks about work, meetings, schedules, and everyday office life. Casual and approachable during conversations, but uses appropriate keigo in professional situations. Patient when the traveller makes mistakes and occasionally asks follow-up questions."
  c.voice = "ja-JP-KeitaNeural"
end

takeshi.image.attach(
  io: File.open(Rails.root.join("db", "character_avatars", "office.png")),
  filename: "office.png",
  content_type: "image/png"
) unless takeshi.image.attached?

hina = Character.find_or_create_by!(name: "Hina") do |c|
  c.persona = "A friendly and professional real estate agent in Tokyo. Helps the user find an apartment, explains properties, rent, fees, and neighborhood details, and guides them through the leasing process. Speaks clear, natural Japanese and patiently explains difficult real estate vocabulary, contracts, and important terms. Asks questions about the traveller's budget, preferred location, and housing needs."
  c.voice = "ja-JP-AoiNeural"
end

hina.image.attach(
  io: File.open(Rails.root.join("db", "character_avatars", "housing.png")),
  filename: "housing.png",
  content_type: "image/png"
) unless hina.image.attached?

puts "Creating scenes..."
Scene.find_or_create_by!(setting: "Tokyo Newsroom", character: yuki) do |s|
  s.description = "You are visiting a Tokyo newsroom. Yuki, a news reporter, is preparing a story about a recent event in Japan. She asks what you think about the news and explains some difficult vocabulary used in the report."
  s.level = "N2"
end

Scene.find_or_create_by!(setting: "Tokyo Office", character: takeshi) do |s|
  s.description = "It's your first week at a Tokyo trading company. Takeshi, your coworker, shows you around the office and talks with you about your schedule, upcoming meetings, and your daily responsibilities."
  s.level = "N2"
end

Scene.find_or_create_by!(setting: "Real Estate Agency", character: hina) do |s|
  s.description = "You are looking for an apartment in Tokyo. Hina, a real estate agent, asks about your budget, preferred neighborhood, and housing requirements. She shows you several apartments and explains the rent, initial fees, and important contract terms."
  s.level = "N2"
end

puts "Creating JLPT entries..."
[
    # N2 Vocabulary
  { entry_type: "word", content: "影響", reading: "えいきょう", level: "N2", meaning: "influence / effect" },
  { entry_type: "word", content: "環境", reading: "かんきょう", level: "N2", meaning: "environment" },
  { entry_type: "word", content: "課題", reading: "かだい", level: "N2", meaning: "task / issue / assignment" },
  { entry_type: "word", content: "解決", reading: "かいけつ", level: "N2", meaning: "solution / resolution" },
  { entry_type: "word", content: "原因", reading: "げんいん", level: "N2", meaning: "cause / reason" },
  { entry_type: "word", content: "結果", reading: "けっか", level: "N2", meaning: "result / outcome" },
  { entry_type: "word", content: "状況", reading: "じょうきょう", level: "N2", meaning: "situation / circumstances" },
  { entry_type: "word", content: "傾向", reading: "けいこう", level: "N2", meaning: "tendency / trend" },
  { entry_type: "word", content: "判断", reading: "はんだん", level: "N2", meaning: "judgment / decision" },
  { entry_type: "word", content: "努力", reading: "どりょく", level: "N2", meaning: "effort" },
  { entry_type: "word", content: "責任", reading: "せきにん", level: "N2", meaning: "responsibility" },
  { entry_type: "word", content: "対策", reading: "たいさく", level: "N2", meaning: "countermeasure / solution" },
  { entry_type: "word", content: "特徴", reading: "とくちょう", level: "N2", meaning: "characteristic / feature" },
  { entry_type: "word", content: "目的", reading: "もくてき", level: "N2", meaning: "purpose / objective" },
  { entry_type: "word", content: "現状", reading: "げんじょう", level: "N2", meaning: "current situation / current state" },
  { entry_type: "word", content: "上昇", reading: "じょうしょう", level: "N2", meaning: "rise / increase" },
  { entry_type: "word", content: "活かせる", reading: "いかせる", level: "N3", meaning: "to be able to utilize / can make use of (potential form of 活かす)" },

  # Grammar
  { entry_type: "grammar", content: "〜わけではない", reading: "わけではない", level: "N2", meaning: "it does not mean that ~ / not necessarily ~" },
  { entry_type: "grammar", content: "〜わけにはいかない", reading: "わけにはいかない", level: "N2", meaning: "cannot afford to / cannot possibly ~" },
  { entry_type: "grammar", content: "〜に違いない", reading: "にちがいない", level: "N2", meaning: "must be / there is no doubt that ~" },
  { entry_type: "grammar", content: "〜ことになっている", reading: "ことになっている", level: "N2", meaning: "it has been decided that ~ / be supposed to ~" },
  { entry_type: "grammar", content: "〜ことはない", reading: "ことはない", level: "N2", meaning: "there is no need to ~" },
  { entry_type: "grammar", content: "〜に対して", reading: "にたいして", level: "N2", meaning: "toward / in contrast to ~" },
  { entry_type: "grammar", content: "〜に加えて", reading: "にくわえて", level: "N2", meaning: "in addition to ~" },
  { entry_type: "grammar", content: "〜に関して", reading: "にかんして", level: "N2", meaning: "regarding / concerning ~" },
  { entry_type: "grammar", content: "〜に基づいて", reading: "にもとづいて", level: "N2", meaning: "based on ~" },
  { entry_type: "grammar", content: "〜おそれがある", reading: "おそれがある", level: "N2", meaning: "there is a risk that ~ / fear that ~" },

  # Expressions / Proverbs
  { entry_type: "proverb", content: "石の上にも三年", reading: "いしのうえにもさんねん", level: "N2", meaning: "perseverance pays off — sit on a stone for three years" },
  { entry_type: "proverb", content: "急がば回れ", reading: "いそがばまわれ", level: "N2", meaning: "more haste, less speed — take the safer route" },
  { entry_type: "proverb", content: "七転び八起き", reading: "ななころびやおき", level: "N2", meaning: "fall seven times, get up eight — never give up" },
  { entry_type: "proverb", content: "口が軽い", reading: "くちがかるい", level: "N2", meaning: "to be unable to keep a secret" },
  { entry_type: "proverb", content: "気が合う", reading: "きがあう", level: "N2", meaning: "to get along well / be compatible" },
  { entry_type: "proverb", content: "猿も木から落ちる", reading: "さるもきからおちる", level: "N2",
    meaning: "even monkeys fall from trees — anyone can make a mistake" },

    # Vocabulary from the 円安 / financial article
  { entry_type: "word", content: "円安", reading: "えんやす", level: "N2", meaning: "weak yen / depreciation of the yen" },
  { entry_type: "word", content: "物価", reading: "ぶっか", level: "N2", meaning: "prices / cost of goods" },
  { entry_type: "word", content: "生活", reading: "せいかつ", level: "N4", meaning: "daily life / livelihood" },
  { entry_type: "word", content: "活かす", reading: "いかす", level: "N2", meaning: "to make use of / utilize" },
  { entry_type: "word", content: "資産", reading: "しさん", level: "N2", meaning: "asset / property" },
  { entry_type: "word", content: "運用", reading: "うんよう", level: "N2", meaning: "management / investment" },
  { entry_type: "word", content: "記事", reading: "きじ", level: "N3", meaning: "article" },
  { entry_type: "word", content: "為替", reading: "かわせ", level: "N2", meaning: "foreign exchange" },
  { entry_type: "word", content: "見通し", reading: "みとおし", level: "N2", meaning: "outlook / forecast / prospects" },
  { entry_type: "word", content: "動向", reading: "どうこう", level: "N2", meaning: "trend / movement / developments" },
  { entry_type: "word", content: "資産運用", reading: "しさんうんよう", level: "N2", meaning: "asset management / investment" },
  { entry_type: "word", content: "効果的", reading: "こうかてき", level: "N3", meaning: "effective" },
  { entry_type: "word", content: "紹介", reading: "しょうかい", level: "N4", meaning: "introduction / presentation" },
  { entry_type: "word", content: "参考", reading: "さんこう", level: "N3", meaning: "reference / something to refer to" },

  # Non-N2 seeds
  { entry_type: "word",    content: "会議",     reading: "かいぎ",      level: "N4", meaning: "meeting" },
  { entry_type: "word",    content: "提出",     reading: "ていしゅつ",  level: "N3", meaning: "submission" },
  { entry_type: "grammar", content: "〜ながら", reading: "ながら",      level: "N4", meaning: "while doing ~" },
  { entry_type: "grammar", content: "〜べき",   reading: "べき",        level: "N3", meaning: "should / ought to" },
].each { |attrs| JlptEntry.create!(attrs) }

if Rails.env.development?
  puts "Users..."

  [
    { username: "James",     email: "james@example.com" },
    { username: "Nina",      email: "nina@example.com" },
    { username: "Cassandra", email: "cassandra@example.com" },
    { username: "Rie",       email: "rie@example.com" }
  ].each do |attrs|
    user = User.find_or_initialize_by(email: attrs[:email])
    user.username = attrs[:username]
    user.password = "password"
    user.save!
  end

  puts "  sign in with any of the above / password"
end

puts "Done: #{Character.count} characters, #{Scene.count} scenes, " \
     "#{JlptEntry.count} entries, #{User.count} users."
