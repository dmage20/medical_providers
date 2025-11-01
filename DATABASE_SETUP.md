# Insurance Broker Database Setup Guide

This application provides both **GraphQL** and **Direct PostgreSQL** access for an insurance broker agent system.

## Overview

The database is designed to manage comprehensive insurance broker operations including:
- **Clients** (individuals and businesses)
- **Insurance Carriers** (insurance companies)
- **Insurance Policies** (all policy types)
- **Policy Quotes**
- **Claims**
- **Commissions**
- **Premiums/Payments**
- **Beneficiaries**
- **Policy Coverages**
- **Policy Documents**
- **Leads/Prospects**
- **Communication Logs**

## Database Setup

### 1. Start PostgreSQL

```bash
# Fix SSL certificate permissions (if needed)
chmod 640 /etc/ssl/private/ssl-cert-snakeoil.key
chown root:ssl-cert /etc/ssl/private/ssl-cert-snakeoil.key

# Start PostgreSQL service
service postgresql start

# Or use systemctl
systemctl start postgresql
```

### 2. Run Database Migrations

```bash
# Create the database
bin/rails db:create

# Run all migrations
bin/rails db:migrate

# Optionally seed with sample data
bin/rails db:seed
```

## API Access Methods

### Method 1: GraphQL API (Recommended for Simple Queries)

The GraphQL API is ideal for:
- Simple data retrieval
- Filtering and pagination
- Client applications
- Mobile apps
- Third-party integrations

#### GraphQL Endpoint

```
POST /graphql
```

#### GraphQL Development Interface

When running in development mode, access GraphiQL at:

```
http://localhost:3000/graphiql
```

#### Example GraphQL Queries

**Fetch all clients:**
```graphql
query {
  clients {
    id
    firstName
    lastName
    email
    status
  }
}
```

**Fetch a specific client with policies:**
```graphql
query {
  client(id: "1") {
    id
    firstName
    lastName
    email
    insurancePolicies {
      policyNumber
      policyType
      premiumAmount
      status
    }
  }
}
```

**Fetch all insurance policies:**
```graphql
query {
  insurancePolicies {
    id
    policyNumber
    policyType
    premiumAmount
    effectiveDate
    expirationDate
    client {
      firstName
      lastName
    }
    insuranceCarrier {
      name
    }
  }
}
```

**Fetch claims:**
```graphql
query {
  claims {
    id
    claimNumber
    claimAmount
    status
    client {
      firstName
      lastName
    }
  }
}
```

#### Example GraphQL Mutations

**Create a new client:**
```graphql
mutation {
  createClient(input: {
    clientType: "individual"
    firstName: "John"
    lastName: "Doe"
    email: "john.doe@example.com"
    phone: "555-0123"
    status: "active"
  }) {
    client {
      id
      firstName
      lastName
      email
    }
    errors
  }
}
```

**Create a new insurance policy:**
```graphql
mutation {
  createInsurancePolicy(input: {
    clientId: "1"
    insuranceCarrierId: "1"
    policyNumber: "POL-2024-001"
    policyType: "health"
    premiumAmount: 450.00
    coverageAmount: 100000.00
    status: "active"
  }) {
    insurancePolicy {
      id
      policyNumber
      policyType
    }
    errors
  }
}
```

**Create a new lead:**
```graphql
mutation {
  createLead(input: {
    source: "website"
    firstName: "Jane"
    lastName: "Smith"
    email: "jane.smith@example.com"
    interestType: "auto_insurance"
    status: "new"
  }) {
    lead {
      id
      firstName
      lastName
      status
    }
    errors
  }
}
```

### Method 2: Direct PostgreSQL Access (for Complex Queries)

Direct PostgreSQL access is ideal for:
- Complex JOIN operations
- Advanced analytics
- Data migrations
- Bulk operations
- Custom reporting

#### Connection Details

**Development:**
```
Host: localhost (or socket)
Port: 5432
Database: provider_directory_development
User: (current OS user or as configured)
Password: (as configured)
```

**Production:**
```
Host: (as configured)
Port: 5432
Database: provider_directory_production
User: provider_directory
Password: Set via PROVIDER_DIRECTORY_DATABASE_PASSWORD env variable
```

#### Connection String

```bash
# Development
postgresql://localhost/provider_directory_development

# Production with credentials
postgresql://provider_directory:PASSWORD@localhost/provider_directory_production
```

#### Example SQL Queries

**Get all active policies with client information:**
```sql
SELECT 
  p.id,
  p.policy_number,
  p.policy_type,
  p.premium_amount,
  p.status,
  c.first_name,
  c.last_name,
  c.email,
  ic.name AS carrier_name
FROM insurance_policies p
JOIN clients c ON c.id = p.client_id
JOIN insurance_carriers ic ON ic.id = p.insurance_carrier_id
WHERE p.status = 'active';
```

**Calculate total commissions by agent:**
```sql
SELECT 
  agent_name,
  COUNT(*) as policy_count,
  SUM(commission_amount) as total_commissions,
  AVG(commission_rate) as avg_commission_rate
FROM commissions
WHERE status = 'paid'
GROUP BY agent_name
ORDER BY total_commissions DESC;
```

**Get claims summary by policy type:**
```sql
SELECT 
  ip.policy_type,
  COUNT(cl.id) as total_claims,
  SUM(cl.claim_amount) as total_claimed,
  SUM(cl.settlement_amount) as total_settled,
  AVG(cl.settlement_amount) as avg_settlement
FROM claims cl
JOIN insurance_policies ip ON ip.id = cl.insurance_policy_id
WHERE cl.status = 'settled'
GROUP BY ip.policy_type;
```

**Complex merge: Update client status based on policy activity:**
```sql
UPDATE clients c
SET status = 'inactive'
WHERE c.id NOT IN (
  SELECT DISTINCT client_id
  FROM insurance_policies
  WHERE status = 'active'
    AND expiration_date > CURRENT_DATE
);
```

## Database Schema

### Core Tables

1. **clients** - Customer information (individuals and businesses)
2. **insurance_carriers** - Insurance company details
3. **insurance_policies** - Policy records
4. **policy_quotes** - Insurance quotes/proposals
5. **policy_coverages** - Coverage details for policies
6. **beneficiaries** - Policy beneficiaries
7. **claims** - Insurance claims
8. **premia** - Premium payments
9. **commissions** - Broker commissions
10. **policy_documents** - Document attachments
11. **leads** - Sales prospects
12. **communication_logs** - Client communication history

### Legacy Tables (NPPES Provider Data)

13. **providers** - Healthcare provider information
14. **addresses** - Provider addresses
15. **taxonomies** - Medical specialties
16. **provider_taxonomies** - Provider specialty assignments
17. And other NPPES-related tables...

## Starting the Application

```bash
# Start the Rails server
bin/rails server

# GraphQL endpoint will be available at:
# http://localhost:3000/graphql

# GraphiQL interface will be available at:
# http://localhost:3000/graphiql
```

## Environment Variables

For production deployment, set these environment variables:

```bash
# Database password
export PROVIDER_DIRECTORY_DATABASE_PASSWORD=your_secure_password

# Database URL (alternative to individual settings)
export DATABASE_URL=postgresql://user:password@host:5432/database_name

# Rails environment
export RAILS_ENV=production
```

## Security Considerations

1. **Never commit** database passwords to version control
2. Use environment variables for sensitive data
3. Implement **authentication** for GraphQL API in production
4. Use **SSL/TLS** for database connections in production
5. Implement **rate limiting** on GraphQL endpoint
6. Consider using **database roles** with limited permissions for agent access

## Testing

```bash
# Run tests
bin/rails test

# Run specific test
bin/rails test test/models/client_test.rb
```

## Troubleshooting

### PostgreSQL won't start

```bash
# Check PostgreSQL status
service postgresql status

# Check logs
tail -f /var/log/postgresql/postgresql-*.log

# Common fixes:
# 1. Fix SSL certificate permissions
chmod 640 /etc/ssl/private/ssl-cert-snakeoil.key

# 2. Check if another process is using port 5432
lsof -i :5432
```

### Database migration errors

```bash
# Rollback last migration
bin/rails db:rollback

# Reset database (⚠️ DESTROYS ALL DATA)
bin/rails db:drop db:create db:migrate
```

### GraphQL errors

```bash
# Check Rails logs
tail -f log/development.log

# Test the endpoint
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ clients { id firstName lastName } }"}'
```

## Additional Resources

- [GraphQL Ruby Documentation](https://graphql-ruby.org/)
- [Rails Guides](https://guides.rubyonrails.org/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
