# frozen_string_literal: true

module KDK
  module Complib
    module SmokeTestHelper
      def retry_until_true(times: 15, delay: 5)
        success = false
        times.times do
          success ||= yield
          break if success == true

          KDK::Output.puts "Retrying..."
          Kernel.sleep delay
        rescue StandardError => e
          KDK::Output.error(e)
          KDK::Output.puts "Retrying..."
          Kernel.sleep delay
          next
        end
        raise "Failed after #{times} attempts." unless success
      end
    end
  end
end
