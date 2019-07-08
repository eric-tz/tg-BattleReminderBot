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
      next_battle_hr = $battle_times[$battle_times.each_with_index.map { |num,i| num - current_time.hour > 0 ? i : nil }.compact.min]
      (next_battle_hr - current_time.hour < 0) ? hr_diff = next_battle_hr : hr_diff = next_battle_hr - current_time.hour
      hr_diff -= 1 if current_time.min > 0
      bot.api.send_message(chat_id: message.chat.id, text: "Next battle will be at #{"UTC " + next_battle_hr.to_s.rjust(2,'0') + "00"}, in #{hr_diff} hours and #{ (60 - current_time.min) % 60 } minutes!")
    elsif message.text == '/subscribe' or message.text == '/subscribe@BattleReminderBot'
      unless subscribed_chats.select { |hash| hash["id"] == message.chat.id }.empty?
        bot.api.send_message(chat_id: message.chat.id, text: "This chat is already subscribed for battle notifications!")
      else
        bot.api.send_message(chat_id: message.chat.id, text: "This chat is now subscribed for battle notifications!")
        subscribed_chats << { "id" => message.chat.id, "aim_levels" => [], "notifies" => {}, "snooze" => [] }
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
        levels = message.text.split(" ").select{ |text| text =~ /\d/}.map{ |text| text.to_i }.sort
        if levels.empty? 
          bot.api.send_message(chat_id: message.chat.id, text: "Please list a space separated list of aim levels to subscribe to!")
          if subscribed_chats[this_chat_index]["aim_levels"].empty?
            bot.api.send_message(chat_id: message.chat.id, text: "This chat is currently not subscribed for any aim levels.")
          else
            bot.api.send_message(chat_id: message.chat.id, text: "This chat is currently subscribed for aim level: #{subscribed_chats[this_chat_index]["aim_levels"].join(",")}")
          end
        else
          subscribed_chats[this_chat_index]["aim_levels"] = levels
          bot.api.send_message(chat_id: message.chat.id, text: "This chat is now subscribed for aim level: #{subscribed_chats[this_chat_index]["aim_levels"].join(",")}")
          write_chat_ids_to_file(subscribed_chats)
        end
      end
    elsif message.text =~ /^\/notify/
      this_chat_index = subscribed_chats.index { |hash| hash["id"] == message.chat.id }
      if this_chat_index.nil?
        bot.api.send_message(chat_id: message.chat.id, text: "Please subscribe this chats to notifications first!")
      else
        aim_levels = message.text.split(" ").select{ |text| text =~ /aim\d/ }.reject { |text| text[/\d+/].to_i > 20 }.sort
        battle_notes = message.text.split(" ").select{ |text| text =~ /battle\d/ }.reject { |text| text[/\d+/].to_i > 3 }.sort
        if aim_levels.empty? && battle_notes.empty?
          if subscribed_chats[this_chat_index]["notifies"].key?(message.from.username)
            bot.api.send_message(chat_id: message.chat.id, text: "@#{message.from.username}, you are currently pinged on #{subscribed_chats[this_chat_index]["notifies"][message.from.username].join(",")}")
          else
            bot.api.send_message(chat_id: message.chat.id, text: "@#{message.from.username} please specify which notifications to subscribe to!")
          end
        elsif aim_levels.empty? && !battle_notes.empty?
          bot.api.send_message(chat_id: message.chat.id, text: "@#{message.from.username} will be notified on battle notifications: #{battle_notes.join(",")}!")
        elsif !aim_levels.empty? && battle_notes.empty?
          bot.api.send_message(chat_id: message.chat.id, text: "@#{message.from.username} will be notified on aim notifications: #{aim_levels.join(",")}!")
        else
          bot.api.send_message(chat_id: message.chat.id, text: "@#{message.from.username} will be notified on battle notifications: #{battle_notes.join(",")} and aim notifications: #{aim_levels.join(",")}!")
        end
        unless aim_levels.empty? && battle_notes.empty?
          subscribed_chats[this_chat_index]["notifies"][message.from.username] = aim_levels + battle_notes
          write_chat_ids_to_file(subscribed_chats)
        end
      end
    elsif message.text =~ /^\/unnotify/
      this_chat_index = subscribed_chats.index { |hash| hash["id"] == message.chat.id }
      if this_chat_index.nil?
        bot.api.send_message(chat_id: message.chat.id, text: "This chat isn't subscribed, how am I supposed to notify you?")
      else
        if subscribed_chats[this_chat_index]["notifies"].keys.include?(message.from.username)
          bot.api.send_message(chat_id: message.chat.id, text: "@#{message.from.username} will not be notified on notifications!")
          subscribed_chats[this_chat_index]["notifies"].delete(message.from.username)
          write_chat_ids_to_file(subscribed_chats)
        else
          bot.api.send_message(chat_id: message.chat.id, text: "@#{message.from.username} was not notified on any notifications yet!")
        end
      end
    elsif message.text =~ /^\/snooze/
      this_chat_index = subscribed_chats.index { |hash| hash["id"] == message.chat.id }
      if this_chat_index.nil?
        bot.api.send_message(chat_id: message.chat.id, text: "This chat isn't subscribed, why am I snoozing?")
      else
        times = message.text.split(" ")[0..-1].last
        if times.nil? && !subscribed_chats[this_chat_index]["snooze"].empty?
          bot.api.send_message(chat_id: message.chat.id, text: "This chat will not receive notifications during the following UTC hours: #{subscribed_chats[this_chat_index]["snooze"].join(",")}")
        elsif times.nil?
          bot.api.send_message(chat_id: message.chat.id, text: "Please send a comma-separated list of UTC hours to snooze during!")
        else
          subscribed_chats[this_chat_index]["snooze"] = []
          times.split(",").each do |time|
            unless time.include?("-")
              subscribed_chats[this_chat_index]["snooze"] << time.to_i
            else
              ((time.split("-").first.to_i)..time.split("-").last.to_i).each do |num|
                subscribed_chats[this_chat_index]["snooze"] << num
              end
            end
          end
          bot.api.send_message(chat_id: message.chat.id, text: "This chat will not receive notifications during the following UTC hours: #{subscribed_chats[this_chat_index]["snooze"].join(",")}")
          write_chat_ids_to_file(subscribed_chats)
        end
      end
    elsif message.text =~ /^\/unsnooze/
      this_chat_index = subscribed_chats.index { |hash| hash["id"] == message.chat.id }
      if this_chat_index.nil?
        bot.api.send_message(chat_id: message.chat.id, text: "This chat isn't subscribed, why am I snoozing?")
      else
        subscribed_chats[this_chat_index]["snooze"] = []
        write_chat_ids_to_file(subscribed_chats)
        bot.api.send_message(chat_id: message.chat.id, text: "Snooze times have been cleared!")
      end
    elsif message.text =~ /^\/help/ || message.text == '/start' || message.text == '/start@BattleReminderBot'
      bot.api.send_message(chat_id: message.chat.id, text: "Bot usage:\n\n/battletime - Time to next battle\n/subscribe - Send battle reminders to current chat automatically\n/unsubscribe - Unsubscribe from notifications\n/aimlevels - Send a space-separated list of aim levels to subscribe to (overwrites).\n/notify - Add ping to defaults. Add list of aim levels to notify on to\n/unnotify - Remove all pings\n")
    end
  end
end
