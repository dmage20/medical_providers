class CommunicationLog < ApplicationRecord
  belongs_to :client
  belongs_to :lead
end
