require 'telegram/bot'

class TelegramBot
  def initialize(token)
    @token = token
    @client = Telegram::Bot::Client.new(token)
  end

  def start
    @client.listen do |message|
      case message.text
      when '/start'
        ask_name(message)
      else
        @client.api.send_message(chat_id: message.chat.id, text: "I don't understand what you mean.")
      end
    end
  end

  private

  def ask_name(message)
    @client.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}! What is your name?")
    @client.listen do |name_message|
      if name_message.text
        name = name_message.text
        ask_university(message, name)
      end
    end
  end

  def ask_university(message, name)
    @client.api.send_message(chat_id: message.chat.id, text: "Nice to meet you, #{name}! Where did you study?")
    @client.listen do |university_message|
      if university_message.text
        university = university_message.text
        ask_dob(message, name, university)
      end
    end
  end

  def ask_dob(message, name, university)
    @client.api.send_message(chat_id: message.chat.id, text: "When were you born? (Please enter your birthdate in the format DD/MM/YYYY)")
    @client.listen do |dob_message|
      if dob_message.text =~ /\d{2}\/\d{2}\/\d{4}/
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
    @client.api.send_message(chat_id: message.chat.id, text: "Please leave your phone number?")
    @client.listen do |phone_number_message|
      if phone_number_message.contact
        phone_number = phone_number_message.contact.phone_number
        Sunscriber.create!(name: name, phone_number: phone_number, status: university,
                           address: state, birthday: dob, socials: source)
        @client.api.send_message(chat_id: message.chat.id, text: "Thank you, we will call you back later.")
      end
    end
  end
end

bot = TelegramBot.new(ENV['TOKEN'])
bot.start
