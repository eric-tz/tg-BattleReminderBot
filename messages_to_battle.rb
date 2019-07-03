require 'telegram/bot'
require 'optparse'
require 'json'
token = File.read("/home/tg_bot/bot_dir/token").chomp
notification_type = ''

OptionParser.new do |opt|
  opt.on('--notification-type NAME') { |o| notification_type = o }
end.parse!

def aim_time(aim_level)
  base = 195
  aim_time = base - [aim_level, 6].min * 15 - [0,[aim_level - 6,4].min].max * 10 - [0,[aim_level - 10,5].min].max * 5
end

$subscribed_chats_file="/home/tg_bot/bot_dir/subscribed_chats.json"

case notification_type
when /aim/
  aim_level = notification_type[/\d+/].to_i
  aim_mins = aim_time(aim_level) + 10
  message = "⚠️ Battle is in #{aim_mins/60}:#{(aim_mins % 60).to_s.rjust(2,'0')}! ⚠️\n\n🏹Rangers with Aiming #{aim_level}, 10 minutes to ready your aim!"
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
    end
    bot.api.send_message(chat_id: hash["id"], text: message)
  end
end

