require 'telegram/bot'

token = File.read("./token").chomp

$subscribed_chats = File.read("/home/tg_bot/bot_dir/subscribed_chats.csv").split("\n").compact.uniq.map{|a| a.to_i }
$battle_times= [ 7,15,23 ]

Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|
    if message.text == '/battletime' or message.text == '/battletime@BattleReminderBot'
      current_time=Time.now
      next_battle_hr = ($battle_times.map { |num| num - current_time.hour }.select { |num| num >= 0 }.min) + current_time.hour
      bot.api.send_message(chat_id: message.chat.id, text: "Next battle will be at #{"UTC " + next_battle_hr.to_s + "00"}, in #{next_battle_hr - current_time.hour - 1} hours and #{ (60 - current_time.min) % 60 } minutes!")
    elsif message.text == '/subscribe' or message.text == '/subscribe@BattleReminderBot'
      if $subscribed_chats.include? message.chat.id
        bot.api.send_message(chat_id: message.chat.id, text: "This chat is already subscribed for battle notifications!")
      else
        bot.api.send_message(chat_id: message.chat.id, text: "This chat is now subscribed for battle notifications!")
        $subscribed_chats << message.chat.id
        open("/home/tg_bot/bot_dir/subscribed_chats.csv",'a') { |f| 
          f << message.chat.id
        }
      end
    end
  end
end
