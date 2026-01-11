# frozen_string_literal: true

require 'resolv'
require 'ipaddr'

module KDK
  module Diagnostic
    class Hostname < Base
      TITLE = 'KDK Hostname'

      def success?
        listen_address.valid? &&
          (match_single(ipv4) || match_single(ipv6))
      end

      def detail
        return if success?

        unless listen_address.valid?
          return <<~MESSAGE
            Provided `listen_address` `#{config.listen_address}` is invalid.
          MESSAGE
        end

        if ipv4.empty? && ipv6.empty?
          return <<~MESSAGE
            Could not resolve IP address for the KDK hostname `#{hostname}`
            Is it set up in `/etc/hosts`?
          MESSAGE
        end

        <<~MESSAGE
          The KDK hostname `#{hostname}` resolves to the IP addresses:
            #{resolved_ips.flatten.join(', ')}

          The listen_address defined in your KDK config is `#{listen_address}`.
          You should make sure that the two match and only contains a single mapping.

          Either fix the IP address in `/etc/hosts` to match `#{listen_address}`,
          remove duplicate mapping for `#{hostname}`, or run either of these commands:

          #{resolved_ips.flatten.map { |ip| "  kdk config set listen_address #{ip}" }.join("\n")}
        MESSAGE
      end

      private

      def match_single(ips)
        ips.size == 1 && ips.first.include?(listen_address)
      end

      def ipv4
        resolved_ips.first
      end

      def ipv6
        resolved_ips.last
      end

      def resolved_ips
        @resolved_ips ||= Resolv
          .getaddresses(hostname)
          .map { |addr| Address.new(addr) }
          .select(&:valid?)
          .partition(&:ipv4?)
      end

      def hostname
        @hostname ||= config.hostname
      end

      def listen_address
        @listen_address ||= Address.new(config.listen_address)
      end

      class Address
        attr_reader :ip_addr

        def initialize(ip_addr)
          @ip_addr = IPAddr.new(ip_addr)
        rescue IPAddr::InvalidAddressError
          @ip_addr = nil
        end

        def to_s
          @ip_addr&.to_s
        end

        def include?(other)
          @ip_addr&.include?(other.ip_addr)
        end

        def ipv4?
          @ip_addr&.ipv4?
        end

        def ipv6?
          @ip_addr&.ipv6?
        end

        def valid?
          !!@ip_addr
        end
      end
    end
  end
end
