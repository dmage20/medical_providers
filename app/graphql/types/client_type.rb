# frozen_string_literal: true

module Types
  class ClientType < Types::BaseObject
    description "A client (individual or business customer)"

    field :id, ID, null: false
    field :client_type, String, null: true
    field :first_name, String, null: true
    field :last_name, String, null: true
    field :business_name, String, null: true
    field :email, String, null: true
    field :phone, String, null: true
    field :date_of_birth, GraphQL::Types::ISO8601Date, null: true
    field :ein, String, null: true
    field :address_line1, String, null: true
    field :address_line2, String, null: true
    field :city, String, null: true
    field :state, String, null: true
    field :postal_code, String, null: true
    field :country, String, null: true
    field :status, String, null: true
    field :assigned_agent, String, null: true
    field :notes, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
