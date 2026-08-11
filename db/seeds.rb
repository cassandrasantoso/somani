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
  { entry_type: "word",    content: "会議",     reading: "かいぎ",      level: "N4", meaning: "meeting" },
  { entry_type: "word",    content: "提出",     reading: "ていしゅつ",  level: "N3", meaning: "submission" },
  { entry_type: "grammar", content: "〜ながら", reading: "ながら",      level: "N4", meaning: "while doing ~" },
  { entry_type: "grammar", content: "〜べき",   reading: "べき",        level: "N3", meaning: "should / ought to" },
  { entry_type: "proverb", content: "猿も木から落ちる", reading: "さるもきからおちる", level: "N2",
    meaning: "even monkeys fall from trees — anyone can make a mistake" }
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
