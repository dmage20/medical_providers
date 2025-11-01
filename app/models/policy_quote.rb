class PolicyQuote < ApplicationRecord
  belongs_to :client
  belongs_to :insurance_carrier
end
