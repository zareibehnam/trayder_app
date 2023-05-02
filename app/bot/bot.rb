require 'telegram/bot'

# Initialize the Telegram bot with your API token
Telegram::Bot::Client.run(ENV["TOKEN"]) do |bot|
  # Listen for messages sent to your bot
  bot.listen do |message|
    # Save the message to the database
    Message.create(
      user_id: message.from.id,
      text: message.text,
      date: Time.at(message.date)
    )

    # Send a response back to the user
    bot.api.send_message(
      chat_id: message.chat.id,
      text: "Thanks for your message!"
    )
  end
end