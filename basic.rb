require 'telegram/bot'
require 'fileutils'

token = File.read("/home/tg_bot/bot_dir/token").chomp

$subscribed_chats_file = "/home/tg_bot/bot_dir/subscribed_chats.csv"

$battle_times= [ 7,15,23 ]

def write_chat_id_to_file(id)
  unless File.readlines($subscribed_chats_file).grep(/#{id.to_s}/).count > 0
    File.open($subscribed_chats_file,'a') { |f| 
      f << id.to_s + "\n"
    }
  end
end

def read_chat_ids_from_file()
  File.read($subscribed_chats_file).split("\n").compact.uniq.map{|a| a.to_i }
end

def delete_chat_id_from_file(id)
  File.open($subscribed_chats_file, "r") do |f|
    File.open("tmp.txt", "w") do |f_tmp|
      f.each_line do |line|
        f_tmp.write(line) unless line.include? id.to_s
      end
    end
  end
  FileUtils.mv("tmp.txt", $subscribed_chats_file)
end

Telegram::Bot::Client.run(token) do |bot|
  subscribed_chats = read_chat_ids_from_file()
  bot.listen do |message|
    if message.text == '/battletime' or message.text == '/battletime@BattleReminderBot'
      current_time=Time.now
      next_battle_hr = ($battle_times.map { |num| num - current_time.hour }.select { |num| num >= 0 }.min) + current_time.hour
      bot.api.send_message(chat_id: message.chat.id, text: "Next battle will be at #{"UTC " + next_battle_hr.to_s + "00"}, in #{next_battle_hr - current_time.hour - 1} hours and #{ (60 - current_time.min) % 60 } minutes!")
    elsif message.text == '/subscribe' or message.text == '/subscribe@BattleReminderBot'
      if subscribed_chats.include? message.chat.id
        bot.api.send_message(chat_id: message.chat.id, text: "This chat is already subscribed for battle notifications!")
      else
        bot.api.send_message(chat_id: message.chat.id, text: "This chat is now subscribed for battle notifications!")
        subscribed_chats << message.chat.id
        write_chat_id_to_file(message.chat.id)
      end
    elsif message.text == '/unsubscribe' or message.text == '/unsubscribe@BattleReminderBot'
      if subscribed_chats.include? message.chat.id
        bot.api.send_message(chat_id: message.chat.id, text: "This chat is now unsubscribed from battle notifications! 😢😢😢")
        subscribed_chats.delete message.chat.id
        delete_chat_id_from_file(message.chat.id)
      else
        bot.api.send_message(chat_id: message.chat.id, text: "This chat was not subscribed for battle notifications!")
      end
    end
  end
end
