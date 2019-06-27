require 'telegram/bot'
require 'optparse'

token = File.read("/home/tg_bot/bot_dir/token").chomp
notification_type = ''

OptionParser.new do |opt|
  opt.on('--notification-type NAME') { |o| notification_type = o }
end.parse!

$subscribed_chats_file="/home/tg_bot/bot_dir/subscribed_chats.csv"

case notification_type
when "T90Battle"
  message = "⚠️ Battle is in 90 minutes! ⚠️\n\n🏹Rangers, ready your aim!"
when "T30Battle"
  message = "⚠️ Battle is in 30 minutes! ⚠️\n\nThings to take note of before a war:\n➡️ If you had forested at night, remember to switch your torches out for battle equipments!\n\n➡️ Spend all your 💰 gold and make sure you have no unplanned transactions ongoing! (Especially if you're selling powder, sticks, leather or thread!)\n\n➡️Use the ⚖️ stock exchange to your advantage, hide your 📦 stocks!\n\n➡️ Check pin for orders!"
when "T8Battle"
  message = "The stock market is now CLOSED.\n\nPlease spend any gold you may have left at the shop and PREPARE FOR BATTLE."
end

Telegram::Bot::Client.run(token) do |bot|
  subscribed_chats = File.read($subscribed_chats_file).split("\n").compact.uniq.map{|a| a.to_i }
  subscribed_chats.each do |id|
    bot.api.send_message(chat_id: id, text: message)
  end
end
