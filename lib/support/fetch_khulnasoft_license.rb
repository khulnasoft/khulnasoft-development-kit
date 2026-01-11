# frozen_string_literal: true

# this script is executed inside the rails console of KhulnaSoft
begin
  unless License.current.present?
    puts({ license_detected: false }.to_json)
    return
  end

  subscription_name = License.current.subscription_name
  duo_add_on_names = KhulnasoftSubscriptions::AddOn.duo_add_ons.map(&:name)
  add_on_purchases = KhulnasoftSubscriptions::AddOnPurchase.joins(:add_on).where(add_on: { name: duo_add_on_names })

  license_data = {
    add_on_purchases: add_on_purchases.map(&:add_on_name),
    duo_core_features_available: License.duo_core_features_available?,
    expiration_date: License.current.expires_at,
    license_detected: true,
    license_type: License.current.license_type,
    number_of_licenses: License.count,
    plan: License.current.plan,
    subscription_name: subscription_name
  }.to_json

  puts(license_data)
rescue StandardError => e
  puts({ error: "Error while fetching the KhulnaSoft license: #{e}" }.to_json)
end
