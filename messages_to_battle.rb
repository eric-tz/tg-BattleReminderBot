require 'telegram/bot'
require 'optparse'
require 'json'
token = File.read("/home/tg_bot/bot_dir/token").chomp
notification_type = ''

OptionParser.new do |opt|
  opt.on('--notification-type NAME') { |o| notification_type = o }
end.parse!

def aim_time(aim_level)
  base = 315
  aim_time = base - [aim_level, 6].min * 15 - [0,[aim_level - 6,4].min].max * 10 - [0,[aim_level - 10,5].min].max * 5
end

$subscribed_chats_file="/home/tg_bot/bot_dir/subscribed_chats.json"

case notification_type
when "aim1"
  message = "⚠️ Battle is in 3:10! ⚠️\n\n🏹Rangers with Aiming 1, 10 minutes to ready your aim!"
when "aim2"
  message = "⚠️ Battle is in 2:55! ⚠️\n\n🏹Rangers with Aiming 2, 10 minutes to ready your aim!"
when "aim3"
  message = "⚠️ Battle is in 2:40! ⚠️\n\n🏹Rangers with Aiming 3, 10 minutes to ready your aim!"
when "aim4"
  message = "⚠️ Battle is in 2:25! ⚠️\n\n🏹Rangers with Aiming 4, 10 minutes to ready your aim!"
when "aim5"
  message = "⚠️ Battle is in 2:10! ⚠️\n\n🏹Rangers with Aiming 5, 10 minutes to ready your aim!"
when "aim6"
  message = "⚠️ Battle is in 1:55! ⚠️\n\n🏹Rangers with Aiming 6, 10 minutes to ready your aim!"
when "aim7"
  message = "⚠️ Battle is in 1:45! ⚠️\n\n🏹Rangers with Aiming 7, 10 minutes to ready your aim!"
when "aim8"
  message = "⚠️ Battle is in 1:35! ⚠️\n\n🏹Rangers with Aiming 8, 10 minutes to ready your aim!"
when "aim9"
  message = "⚠️ Battle is in 1:25! ⚠️\n\n🏹Rangers with Aiming 9, 10 minutes to ready your aim!"
when "aim10"
  message = "⚠️ Battle is in 1:15! ⚠️\n\n🏹Rangers with Aiming 10, 10 minutes to ready your aim!"
when "aim11"
  message = "⚠️ Battle is in 1:10! ⚠️\n\n🏹Rangers with Aiming 11, 10 minutes to ready your aim!"
when "aim12"
  message = "⚠️ Battle is in 1:05! ⚠️\n\n🏹Rangers with Aiming 12, 10 minutes to ready your aim!"
when "aim13"
  message = "⚠️ Battle is in 1:00! ⚠️\n\n🏹Rangers with Aiming 13, 10 minutes to ready your aim!"
when "aim14"
  message = "⚠️ Battle is in 0:55! ⚠️\n\n🏹Rangers with Aiming 14, 10 minutes to ready your aim!"
when "aim15"
  message = "⚠️ Battle is in 0:50! ⚠️\n\n🏹Rangers with Aiming 15, 10 minutes to ready your aim!"
when "T30Battle"
  message = "⚠️ Battle is in 30 minutes! ⚠️\n\nThings to take note of before a war:\n➡️ If you had forested at night, remember to switch your torches out for battle equipments!\n\n➡️ Spend all your 💰 gold and make sure you have no unplanned transactions ongoing! (Especially if you're selling powder, sticks, leather or thread!)\n\n➡️Use the ⚖️ stock exchange to your advantage, hide your 📦 stocks!\n\n➡️ Check pin for orders!"
when "T8Battle"
  message = "The stock market is now CLOSED.\n\nPlease spend any gold you may have left at the shop and PREPARE FOR BATTLE."
end

Telegram::Bot::Client.run(token) do |bot|
  subscribed_chats = JSON.parse(File.read($subscribed_chats_file))
  subscribed_chats.each do |hash|
    if notification_type =~ /aim/
      next unless hash["aim_levels"].include?(notification_type[/\d+/].to_i)
      bot.api.send_message(chat_id: hash["id"], text: message)
    end
  end
end

