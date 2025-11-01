# frozen_string_literal: true

module Types
  class CommunicationLogType < Types::BaseObject
    description "A communication log entry"

    field :id, ID, null: false
    field :communication_type, String, null: true
    field :communication_date, GraphQL::Types::ISO8601DateTime, null: true
    field :subject, String, null: true
    field :content, String, null: true
    field :direction, String, null: true
    field :agent_name, String, null: true
    field :follow_up_required, Boolean, null: true
    field :follow_up_date, GraphQL::Types::ISO8601Date, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    
    field :client, Types::ClientType, null: true
    field :lead, Types::LeadType, null: true
  end
end
