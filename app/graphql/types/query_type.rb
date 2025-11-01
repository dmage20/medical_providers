# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :node, Types::NodeType, null: true, description: "Fetches an object given its ID." do
      argument :id, ID, required: true, description: "ID of the object."
    end

    def node(id:)
      context.schema.object_from_id(id, context)
    end

    field :nodes, [Types::NodeType, null: true], null: true, description: "Fetches a list of objects given a list of IDs." do
      argument :ids, [ID], required: true, description: "IDs of the objects."
    end

    def nodes(ids:)
      ids.map { |id| context.schema.object_from_id(id, context) }
    end

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    # Client queries
    field :clients, [Types::ClientType], null: false, description: "Fetch all clients"
    field :client, Types::ClientType, null: true, description: "Fetch a single client" do
      argument :id, ID, required: true
    end

    def clients
      Client.all
    end

    def client(id:)
      Client.find_by(id: id)
    end

    # Insurance Carrier queries
    field :insurance_carriers, [Types::InsuranceCarrierType], null: false, description: "Fetch all insurance carriers"
    field :insurance_carrier, Types::InsuranceCarrierType, null: true, description: "Fetch a single insurance carrier" do
      argument :id, ID, required: true
    end

    def insurance_carriers
      InsuranceCarrier.all
    end

    def insurance_carrier(id:)
      InsuranceCarrier.find_by(id: id)
    end

    # Insurance Policy queries
    field :insurance_policies, [Types::InsurancePolicyType], null: false, description: "Fetch all insurance policies"
    field :insurance_policy, Types::InsurancePolicyType, null: true, description: "Fetch a single insurance policy" do
      argument :id, ID, required: true
    end

    def insurance_policies
      InsurancePolicy.all
    end

    def insurance_policy(id:)
      InsurancePolicy.find_by(id: id)
    end

    # Lead queries
    field :leads, [Types::LeadType], null: false, description: "Fetch all leads"
    field :lead, Types::LeadType, null: true, description: "Fetch a single lead" do
      argument :id, ID, required: true
    end

    def leads
      Lead.all
    end

    def lead(id:)
      Lead.find_by(id: id)
    end

    # Claim queries
    field :claims, [Types::ClaimType], null: false, description: "Fetch all claims"
    field :claim, Types::ClaimType, null: true, description: "Fetch a single claim" do
      argument :id, ID, required: true
    end

    def claims
      Claim.all
    end

    def claim(id:)
      Claim.find_by(id: id)
    end

    # Commission queries
    field :commissions, [Types::CommissionType], null: false, description: "Fetch all commissions"
    field :commission, Types::CommissionType, null: true, description: "Fetch a single commission" do
      argument :id, ID, required: true
    end

    def commissions
      Commission.all
    end

    def commission(id:)
      Commission.find_by(id: id)
    end

    # Policy Document queries
    field :policy_documents, [Types::PolicyDocumentType], null: false, description: "Fetch all policy documents"
    field :policy_document, Types::PolicyDocumentType, null: true, description: "Fetch a single policy document" do
      argument :id, ID, required: true
    end

    def policy_documents
      PolicyDocument.all
    end

    def policy_document(id:)
      PolicyDocument.find_by(id: id)
    end

    # Communication Log queries
    field :communication_logs, [Types::CommunicationLogType], null: false, description: "Fetch all communication logs"
    field :communication_log, Types::CommunicationLogType, null: true, description: "Fetch a single communication log" do
      argument :id, ID, required: true
    end

    def communication_logs
      CommunicationLog.all
    end

    def communication_log(id:)
      CommunicationLog.find_by(id: id)
    end
  end
end
