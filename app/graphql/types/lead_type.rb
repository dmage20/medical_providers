# frozen_string_literal: true

module Types
  class LeadType < Types::BaseObject
    description "A sales lead/prospect"

    field :id, ID, null: false
    field :source, String, null: true
    field :first_name, String, null: true
    field :last_name, String, null: true
    field :business_name, String, null: true
    field :email, String, null: true
    field :phone, String, null: true
    field :interest_type, String, null: true
    field :status, String, null: true
    field :assigned_agent, String, null: true
    field :contact_date, GraphQL::Types::ISO8601Date, null: true
    field :follow_up_date, GraphQL::Types::ISO8601Date, null: true
    field :notes, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    
    field :client, Types::ClientType, null: true
  end
end
