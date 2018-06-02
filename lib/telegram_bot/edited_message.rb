module TelegramBot
  class EditedMessage
    include Virtus.model
    attribute :message_id, Integer
    alias_method :id, :message_id
    alias_method :to_i, :id
    attribute :from, User
    alias_method :user, :from
    attribute :date, DateTime
    attribute :text, String
    attribute :edit_date, DateTime
    attribute :chat, Channel
    attribute :reply_to_message, EditedMessage
    attribute :location, Location

    def reply(&block)
      reply = OutMessage.new(chat: chat)
      yield reply if block_given?
      reply
    end

    def get_command_for(bot)
      text && text.sub(Regexp.new("@#{bot.identity.username}($|\s|\.|,)", Regexp::IGNORECASE), '').strip
    end

    def edited?
      true
    end
  end
end
