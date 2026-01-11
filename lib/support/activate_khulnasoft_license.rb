# frozen_string_literal: true

# this script is executed inside the rails console of KhulnaSoft
begin
  license_file_path = ARGV.first
  license_details = JSON.parse(File.read(license_file_path), symbolize_names: true)

  return if License.current&.cloud? && License.current.plan == license_details[:khulnasoft_tier]

  License.current&.destroy

  License.create!(data: license_details[:activation_code].gsub("\\n", "\n"), cloud: true)
  Khulnasoft::SeatLinkData.new(refresh_token: true).sync

  if license_details[:duo_tier] == 'enterprise'
    add_on_purchase = KhulnasoftSubscriptions::AddOnPurchase.joins(:add_on).find_by(add_on: { name: 'duo_enterprise' })
    add_on_purchase.assigned_users.update!(KhulnasoftSubscriptions::UserAddOnAssignment.create!(add_on_purchase: add_on_purchase, user: User.find_by_username('root')))
  end
rescue StandardError => e
  puts "Error: Failed to activate KhulnaSoft license: #{e.message}"
end
