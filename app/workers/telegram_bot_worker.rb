class TelegramBotWorker
  include Sidekiq::Worker

  def perform(token)
    bot = TelegramBot.new(token)
    bot.start
  end
end

