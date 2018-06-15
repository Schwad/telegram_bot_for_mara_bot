module TelegramBot
  class Bot
    ENDPOINT = 'https://api.telegram.org/'

    def initialize(opts = {})
      # compatibility with just passing a token
      if opts.is_a?(String)
        opts = { token: opts }
      end

      @token = opts.fetch(:token)
      @timeout = opts[:timeout] || 50
      @offset = opts[:offset] || 0
      @logger = opts[:logger] || NullLogger.new
      @proxy = opts[:proxy] || nil
      @connection = Excon.new(ENDPOINT, persistent: true, proxy: @proxy)
    end

    def get_me
      @me ||= begin
                response = request(:getMe)
                User.new(response.result)
              end
    end
    alias_method :me, :get_me
    alias_method :identity, :me

    def get_updates(opts = {}, &block)
      return get_last_updates(opts) unless block_given?

      logger.info "starting get_updates loop"
      loop do
        messages = get_last_updates(opts)
        messages.compact.each do |message|
          next unless message
          logger.info "message from @#{message.chat.friendly_name}: #{message.text.inspect}"
          yield message
        end
      end
    end

    def send_message(out_message)
      logger.info "sending message: #{out_message.text.inspect} to #{out_message.chat_friendly_name}"
      response = request(:sendMessage, out_message.to_h)
      Message.new(response.result)
    end

    def set_webhook(url, allowed_updates: %i(message edited_message))
      logger.info "setting webhook url to #{url}, allowed_updates: #{allowed_updates}"
      settings = {
        url: url,
        allowed_updates: allowed_updates.map(&:to_s),
      }
      request(:setWebhook, settings)
    end

    def remove_webhook
      set_webhook("")
    end

    private
    attr_reader :token
    attr_reader :logger

    def request(action, query = {})
      path = "/bot#{@token}/#{action}"
      res = @connection.post(path: path, query: query)
      ApiResponse.new(res)
    end

    def get_last_updates(opts = {})
      response = request(:getUpdates, offset: opts[:offset] || @offset, timeout: opts[:timeout] || @timeout)
      if opts[:fail_silently] && (!response.ok? || !response.result)
        logger.warn "error when getting updates. ignoring due to fail_silently."
        return []
      end
      updates = response.result.map{|raw_update| Update.new(raw_update) }
      @offset = updates.last.id + 1 if updates.any?
      updates.map(&:message) + updates.map(&:edited_message)
    end
  end
end
