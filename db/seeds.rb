# db/seeds.rb
puts "Cleaning seed tables..."
Scene.destroy_all
Character.destroy_all
JlptEntry.destroy_all

puts "Creating characters..."
yuki = Character.create!(
  name: "Yuki",
  persona: "A friendly colleague at a Tokyo trading company. Speaks polite " \
           "business Japanese, patient with mistakes, asks follow-up questions.",
  voice: "ja-JP-NanamiNeural"
)

takeshi = Character.create!(
  name: "Takeshi",
  persona: "A samurai retainer in late Edo-period Kyoto. Formal, archaic " \
           "register, but slows down when the traveller looks confused.",
  voice: "ja-JP-KeitaNeural"
)

hina = Character.create!(
  name: "Hina",
  persona: "A language exchange partner. Casual, fast-paced, pushes the " \
           "learner to read and reply quickly.",
  voice: "ja-JP-AoiNeural"
)

puts "Creating scenes..."
Scene.create!(
  setting: "The office",
  description: "You've just joined a trading company in Shinbashi. Yuki " \
               "shows you to your desk and asks about your first week.",
  level: "N4",
  character: yuki
)

Scene.create!(
  setting: "Back in time (samurai)",
  description: "You wake up on the Tokaido road in 1860. A retainer stops " \
               "you and demands to know your domain.",
  level: "N3",
  character: takeshi
)

Scene.create!(
  setting: "Speed reading cafe",
  description: "Hina sets a timer and challenges you to read each line " \
               "before it disappears.",
  level: "N4",
  character: hina
)

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
  { entry_type: "proverb", content: "気が合う", reading: "きがあう", level: "N2", meaning: "to get along well / be compatible" }
  { entry_type: "proverb", content: "猿も木から落ちる", reading: "さるもきからおちる", level: "N2",
    meaning: "even monkeys fall from trees — anyone can make a mistake" }

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
