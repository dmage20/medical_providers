class Claim < ApplicationRecord
  belongs_to :insurance_policy
  belongs_to :client
end
