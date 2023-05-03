require 'telegram/bot'
require_relative 'models/sunscriber.rb'
class TelegramBot
  def initialize(token)
    @token = token
    @client = Telegram::Bot::Client.new(token)
  end

  def start
    lock_file = File.new('bot.lock', File::CREAT|File::EXCL)
    begin
      @client.listen do |message|
        begin
        if message.is_a?(Telegram::Bot::Types::Message) && message.text
          case message.text
          when '/start'
            ask_name(message)
          else
            @client.api.send_message(chat_id: message.chat.id, text: "I don't understand what you mean.")
          end
        end
        rescue => e
          puts "Error processing message: #{e.message}"
        end
      end
    ensure
      lock_file.close
      File.delete('bot.lock')
    end
  end

  private

  def ask_name(message)
    @client.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}! What is your name?")
    @client.listen do |name_message|
      if message.is_a?(Telegram::Bot::Types::Message) && name_message.text
        name = name_message.text
        ask_university(message, name)
      end
    end
  end

  def ask_university(message, name)
    @client.api.send_message(chat_id: message.chat.id, text: "Nice to meet you, #{name}! Where did you study?")
    @client.listen do |university_message|
      if message.is_a?(Telegram::Bot::Types::Message) && university_message.text
        university = university_message.text
        ask_dob(message, name, university)
      end
    end
  end

  def ask_dob(message, name, university)
    @client.api.send_message(chat_id: message.chat.id, text: "When were you born? (Please enter your birthdate in the format DD/MM/YYYY)")
    @client.listen do |dob_message|
      if message.is_a?(Telegram::Bot::Types::Message) && dob_message.text =~ /\d{2}\/\d{2}\/\d{4}/
        dob = dob_message.text
        ask_state(message, name, university, dob)
      else
        @client.api.send_message(chat_id: message.chat.id, text: "Invalid date format. Please try again. (DD/MM/YYYY)")
      end
    end
  end

  def ask_state(message,name, university, dob)
      states = ['Alabama', 'Alaska', 'Arizona']
      buttons = states.each_slice(3).map { |state| state.map { |s| Telegram::Bot::Types::InlineKeyboardButton.new(text: s, callback_data: s) } }
      @client.api.send_message(chat_id: message.chat.id, text: "Which state are you from?", reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons))
      @client.listen do |state_message|
        if state_message.data
          state = state_message.data
          ask_phone_number(message, state, name, university, dob)
        end
      end
    end

  def ask_phone_number(message, state, name, university, dob)
    # Create a reply keyboard with a single button to request phone number
    button = Telegram::Bot::Types::KeyboardButton.new(text: "Share my phone number", request_contact: true)
    keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [[button]], one_time_keyboard: true)

    # Ask the user to share their phone number using the reply keyboard
    @client.api.send_message(chat_id: message.chat.id, text: "Please share your phone number", reply_markup: keyboard)

    # Listen for a contact message with the phone number
    @client.listen do |contact_message|
      if contact_message.contact
        phone_number = contact_message.contact.phone_number
        a = ::Sunscriber.create!(name: name, phone_number: phone_number, status: university, address: state, birthday: dob)
        Rails.logger.info  "created instance" + a
        @client.api.send_message(chat_id: message.chat.id, text: "Thank you, we will call you back later.")
      end
    end
  end

end

bot = TelegramBot.new(ENV['TOKEN'])
bot.start
