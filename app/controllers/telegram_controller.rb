require 'telegram/bot'
class TelegramController < ApplicationController
  def bot
    token = ENV['TOKEN']

    Telegram::Bot::Client.run(token) do |bot|
      bot.listen do |message|
        case message.text
        when '/start'
          # Приветствие и первый вопрос
          bot.api.send_message(chat_id: message.chat.id, text: "Привет! Как тебя зовут?")
        when /([А-Яа-яЁё]+)|([a-zA-Z]+)/ # регулярное выражение для имени пользователя
          # Сохраняем имя пользователя в базе данных и задаем следующий вопрос
          name = message.text
          @payer = Payer.create(name: name)
          bot.api.send_message(chat_id: message.chat.id, text: "Приятно познакомиться, #{name}. В каком районе ты проживаешь?")
        when /([А-Яа-яЁё]+\s*)+/ # регулярное выражение для района проживания пользователя
          # Сохраняем район проживания пользователя в базе данных и завершаем работу
          district = message.text
          @payer.update(district: district)
          bot.api.send_message(chat_id: message.chat.id, text: "Спасибо за ответ! Желаю хорошего дня!")
        else
          # Если пользователь ввел что-то не то, повторяем последний вопрос
          bot.api.send_message(chat_id: message.chat.id, text: "Извините, я не понял ваш ответ. Пожалуйста, попробуйте еще раз.")
        end
      end
    end
  end
end
