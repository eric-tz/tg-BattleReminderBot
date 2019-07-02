require 'telegram/bot'
require 'fileutils'
require 'json'

token = File.read("/home/tg_bot/bot_dir/token").chomp

$subscribed_chats_file = "/home/tg_bot/bot_dir/subscribed_chats.json"

$battle_times= [ 7,15,23 ]

def read_chat_ids_from_file()
  JSON.parse(File.read("subscribed_chats.json"))
end

def write_chat_ids_to_file(chat_ids)
  File.open("tmp.txt", "w") do |f_tmp|
      f_tmp.write(chat_ids.to_json)
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
      unless subscribed_chats.select { |hash| hash["id"] == message.chat.id }.empty?
        bot.api.send_message(chat_id: message.chat.id, text: "This chat is already subscribed for battle notifications!")
      else
        bot.api.send_message(chat_id: message.chat.id, text: "This chat is now subscribed for battle notifications!")
        subscribed_chats << { "id" => message.chat.id, "aim_levels" => [] }
        write_chat_ids_to_file(subscribed_chats)
      end
    elsif message.text == '/unsubscribe' or message.text == '/unsubscribe@BattleReminderBot'
      unless subscribed_chats.select { |hash| hash["id"] == message.chat.id }.empty?
        bot.api.send_message(chat_id: message.chat.id, text: "This chat is now unsubscribed from battle notifications! 😢😢😢")
        subscribed_chats.reject! {|hash| hash["id"] == message.chat.id }
        write_chat_ids_to_file(subscribed_chats)
      else
        bot.api.send_message(chat_id: message.chat.id, text: "This chat was not subscribed for battle notifications!")
      end
    elsif message.text =~ /^\/aimlevels/
      this_chat_index = subscribed_chats.index { |hash| hash["id"] == message.chat.id }
      if this_chat_index.nil?
        bot.api.send_message(chat_id: message.chat.id, text: "Please subscribe this chats to notifications first!")
      else
        levels = message.text.split(" ").select{ |text| text =~ /\d/}.map{ |text| text.to_i }
        if levels.empty? 
          bot.api.send_message(chat_id: message.chat.id, text: "Please list a space separated list of aim levels to subscribe to!")
          if subscribed_chats[this_chat_index]["aim_levels"].empty?
            bot.api.send_message(chat_id: message.chat.id, text: "This chat is currently not subscribed for any aim levels.")
          else
            bot.api.send_message(chat_id: message.chat.id, text: "This chat is currently subscribed for aim levels: #{subscribed_chats[this_chat_index]["aim_levels"].join(",")}")
          end
        else
          subscribed_chats[this_chat_index]["aim_levels"] = levels
          bot.api.send_message(chat_id: message.chat.id, text: "This chat is now subscribed for aim levels: #{subscribed_chats[this_chat_index]["aim_levels"].join(",")}")
          write_chat_ids_to_file(subscribed_chats)
        end
      end
    end
  end
end
