# frozen_string_literal: true

require 'net/http'
require 'json'
begin
  require 'tty-markdown'
rescue LoadError
end

module KDK
  class DuoConnector
    KHULNASOFT_CHAT_COMPLETIONS_URL = 'https://khulnasoft.com/api/v4/chat/completions'
    AUTH_TOKEN_ENV_VARS = %w[KHULNASOFT_AUTH_TOKEN KHULNASOFT_TOKEN KHULNASOFT_API_PRIVATE_TOKEN].freeze

    DuoConnectorError = Class.new(StandardError)

    def initialize(out)
      @out = out
    end

    def call(prompt, issues)
      if auth_token.nil?
        out.warn('AI assistance for troubleshooting is missing the KhulnaSoft auth token.')
        out.info("Set one of the following environment variables: #{AUTH_TOKEN_ENV_VARS.join(', ')}")
        out.info('Example: export KHULNASOFT_TOKEN=<your-khulnasoft-auth-token>')
        return
      end

      messages = create_chats(create_prompts(prompt, issues))

      messages.each do |message|
        display_message(message)
      end
    end

    private

    attr_accessor :out

    def create_chats(prompts)
      uri = URI(KHULNASOFT_CHAT_COMPLETIONS_URL)
      request = Net::HTTP::Post.new(uri)
      request.content_type = 'application/json'
      request['Authorization'] = "Bearer #{auth_token}"
      request_options = { use_ssl: uri.scheme == 'https' }

      prompts.each_with_object([]) do |prompt, messages|
        request.body = prompt

        response = begin
          Net::HTTP.start(uri.hostname, uri.port, request_options) do |http|
            http.request(request)
          end
        rescue StandardError => e
          raise DuoConnectorError.new, "Failed to reach KhulnaSoft: #{e.message}"
        end

        unless response.is_a?(Net::HTTPSuccess)
          error_message = "KhulnaSoft Duo API request failed with status #{response.code}"
          begin
            parsed_error = JSON.parse(response.body)
            error_message += ": #{parsed_error['error'] || parsed_error['message'] || response.body}"
          rescue JSON::ParserError
            error_message += ": #{response.body}" unless response.body.to_s.empty?
          end
          raise DuoConnectorError.new, error_message
        end

        begin
          parsed_response = JSON.parse(response.body)
        rescue StandardError => e
          raise DuoConnectorError.new, "There was an error while parsing the response from KhulnaSoft Duo: #{e.message}"
        end

        raise DuoConnectorError.new, "The request to KhulnaSoft Duo returned an error: #{response.code} #{parsed_response['error']}" if !parsed_response.is_a?(String) && parsed_response['error']

        messages << parsed_response
      end
    end

    def create_prompts(prompt, issues)
      joined_content_json = { content: "#{prompt} #{issues.join("\n")}" }.to_json
      return [joined_content_json] if joined_content_json.length < 1000 # KhulnaSoft Duo only allows content with less than 1000 characters

      issues.each_with_object([]) do |issue, content_array|
        issue_prompt_json = { content: "#{prompt} #{issue}" }.to_json
        if issue_prompt_json.length > 1000
          # skip reporting to KhulnaSoft Duo
          out.puts "This issue is too long to be reported to KhulnaSoft Duo: #{issue[0, 50]}"
          next
        end

        content_array << issue_prompt_json
      end
    end

    def display_message(message)
      return '' if message.empty?

      unless defined?(TTY::Markdown)
        out.puts(message)
        return
      end

      options = { width: 80, color: out.colorize? ? :always : :never }
      out.puts TTY::Markdown.parse(message, **options)
      out.puts
    end

    def auth_token
      AUTH_TOKEN_ENV_VARS.each do |var|
        token = ENV.fetch(var, nil)
        return token unless token.nil? || token.empty?
      end
      nil
    end
  end
end
