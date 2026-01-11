# frozen_string_literal: true

module KDK
  # Succeeds in telemetry but fails the current command.
  #
  # Use cases are e.g. permission, network, or config issues where
  # user interaction will (!) resolve this issue because KDK can't.
  # For example, prompting the user to configure SSH auth to KhulnaSoft.com.
  #
  # To improve the user experience, the error allows passing a `docs`
  # parameter, with a link to a KhulnaSoft documentation page. For example:
  #
  # UserInteractionRequired.new('Please configure Git authentication', docs: 'troubleshooting/git.md#configure-authentication')
  #
  # You can raise this error without a message but you must have printed
  # a helpful (error) message before raising this.
  UserInteractionRequired = Class.new(StandardError) do
    def initialize(message, docs: nil)
      message ||= ""
      super(message)
      @docs = docs
    end

    def print!
      out.error(message, report_error: false) unless message.empty?

      return unless @docs

      out.puts
      out.info("See #{out.wrap_in_color(docs_url, out::COLOR_CODE_BLUE)} for details.")
    end

    private

    def out
      KDK::Output
    end

    def docs_url
      return unless @docs

      if @docs.start_with?('http')
        @docs
      else
        "https://github.com/khulnasoft/khulnasoft-development-kit/-/tree/main/doc/#{@docs}"
      end
    end
  end
end
