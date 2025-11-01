# frozen_string_literal: true

module Types
  class PolicyDocumentType < Types::BaseObject
    description "A policy document or attachment"

    field :id, ID, null: false
    field :document_type, String, null: true
    field :document_name, String, null: true
    field :file_url, String, null: true
    field :file_size, Integer, null: true
    field :uploaded_date, GraphQL::Types::ISO8601Date, null: true
    field :description, String, null: true
    field :status, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    
    field :insurance_policy, Types::InsurancePolicyType, null: true
    field :client, Types::ClientType, null: true
  end
end
