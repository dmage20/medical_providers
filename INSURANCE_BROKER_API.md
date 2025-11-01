# Insurance Broker Database & API

A comprehensive database and API system for insurance broker agents to manage clients, policies, claims, commissions, and more.

## Features

### Dual API Access

1. **GraphQL API** - For simple queries and standard CRUD operations
2. **Direct PostgreSQL Access** - For complex analytics and bulk operations

### Insurance Broker Management

- **Client Management** - Track individual and business clients
- **Policy Management** - Manage all types of insurance policies
- **Lead Tracking** - Convert prospects to clients
- **Claims Processing** - Track and manage insurance claims
- **Commission Tracking** - Monitor broker commissions and payments
- **Document Management** - Store policy documents and attachments
- **Communication Logs** - Track all client interactions
- **Quote Management** - Create and manage policy quotes

### Data Models

#### Core Entities

1. **Clients** - Customer records (individual/business)
   - Contact information
   - Address details
   - Status tracking
   - Associated policies, claims, and documents

2. **Insurance Carriers** - Insurance company information
   - Company details
   - Contact information
   - Ratings and status

3. **Insurance Policies** - Policy records
   - Policy numbers and types
   - Coverage amounts and deductibles
   - Premium information
   - Policy dates and status
   - Associated coverages and beneficiaries

4. **Policy Quotes** - Insurance quotes
   - Quoted premiums
   - Coverage details
   - Quote expiration dates

5. **Claims** - Insurance claims
   - Claim amounts
   - Settlement tracking
   - Status monitoring

6. **Commissions** - Broker commissions
   - Commission rates and amounts
   - Payment tracking
   - Period information

7. **Leads** - Sales prospects
   - Contact information
   - Interest tracking
   - Follow-up management

8. **Communication Logs** - Client interactions
   - Communication history
   - Follow-up tracking
   - Agent notes

## Quick Start

### Prerequisites

- Ruby 3.2.3+
- Rails 7.2.2+
- PostgreSQL 14+
- Bundler

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd review_ruby_concepts

# Install dependencies
bundle install

# Setup database
bin/rails db:create
bin/rails db:migrate

# Start the server
bin/rails server
```

### Access the APIs

**GraphQL Endpoint:**
```
POST http://localhost:3000/graphql
```

**GraphiQL Interface (Development):**
```
http://localhost:3000/graphiql
```

## Usage Examples

### GraphQL Queries

```graphql
# Get all clients
query {
  clients {
    id
    firstName
    lastName
    email
    insurancePolicies {
      policyNumber
      status
    }
  }
}

# Get specific policy with details
query {
  insurancePolicy(id: "1") {
    policyNumber
    policyType
    premiumAmount
    client {
      firstName
      lastName
    }
    insuranceCarrier {
      name
      rating
    }
  }
}

# Get commission summary
query {
  commissions {
    agentName
    commissionAmount
    paymentDate
    status
  }
}
```

### GraphQL Mutations

```graphql
# Create a new client
mutation {
  createClient(input: {
    firstName: "John"
    lastName: "Doe"
    email: "john@example.com"
    clientType: "individual"
    status: "active"
  }) {
    client {
      id
      firstName
      lastName
    }
    errors
  }
}

# Create a policy
mutation {
  createInsurancePolicy(input: {
    clientId: "1"
    insuranceCarrierId: "1"
    policyType: "health"
    policyNumber: "POL-001"
    premiumAmount: 500.00
    status: "active"
  }) {
    insurancePolicy {
      id
      policyNumber
    }
    errors
  }
}
```

### Direct SQL Queries

```sql
-- Get active policies with client info
SELECT p.*, c.first_name, c.last_name, ic.name as carrier
FROM insurance_policies p
JOIN clients c ON c.id = p.client_id
JOIN insurance_carriers ic ON ic.id = p.insurance_carrier_id
WHERE p.status = 'active';

-- Commission analysis
SELECT agent_name, SUM(commission_amount) as total
FROM commissions
WHERE status = 'paid'
GROUP BY agent_name
ORDER BY total DESC;
```

## Architecture

### Technology Stack

- **Framework:** Ruby on Rails 7.2.2
- **Language:** Ruby 3.2.3
- **Database:** PostgreSQL 14+
- **GraphQL:** graphql-ruby 2.4+
- **API:** REST + GraphQL

### Database Design

The schema includes:
- 12 insurance broker tables
- 12 legacy NPPES healthcare provider tables
- Comprehensive indexes for performance
- Foreign key constraints for data integrity

## Configuration

### Database Connection

Edit `config/database.yml` for database settings.

**Development:**
```yaml
development:
  adapter: postgresql
  database: provider_directory_development
```

**Production:**
```yaml
production:
  database: provider_directory_production
  username: provider_directory
  password: <%= ENV["PROVIDER_DIRECTORY_DATABASE_PASSWORD"] %>
```

### Environment Variables

```bash
# Database password (production)
PROVIDER_DIRECTORY_DATABASE_PASSWORD=your_password

# Database URL (alternative)
DATABASE_URL=postgresql://user:pass@host:5432/dbname

# Rails environment
RAILS_ENV=production
```

## API Documentation

See [DATABASE_SETUP.md](DATABASE_SETUP.md) for comprehensive API documentation including:
- Complete GraphQL query examples
- Mutation examples
- SQL query patterns
- Connection details
- Security guidelines

## Development

### Running Tests

```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/client_test.rb

# Run with coverage
COVERAGE=true bin/rails test
```

### Code Quality

```bash
# Run RuboCop linter
bundle exec rubocop

# Auto-fix issues
bundle exec rubocop -a
```

### Database Management

```bash
# Create database
bin/rails db:create

# Run migrations
bin/rails db:migrate

# Rollback migration
bin/rails db:rollback

# Reset database (⚠️ destroys data)
bin/rails db:drop db:create db:migrate
```

## Deployment

### Production Setup

1. Set environment variables
2. Precompile assets: `bin/rails assets:precompile`
3. Run migrations: `bin/rails db:migrate RAILS_ENV=production`
4. Start server with production config

### Docker Deployment

A Dockerfile is included for containerized deployment.

```bash
# Build image
docker build -t insurance-broker-api .

# Run container
docker run -p 3000:3000 insurance-broker-api
```

## Security

- Never commit sensitive credentials
- Use environment variables for secrets
- Implement authentication for production GraphQL endpoint
- Use SSL/TLS for database connections
- Implement rate limiting
- Use database roles with minimal permissions

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## License

[Specify your license here]

## Support

For issues and questions:
- Check [DATABASE_SETUP.md](DATABASE_SETUP.md) for setup help
- Review Rails logs: `tail -f log/development.log`
- Check PostgreSQL logs for database issues

## Roadmap

Future enhancements:
- [ ] Authentication and authorization
- [ ] Real-time notifications via Action Cable
- [ ] Advanced reporting dashboards
- [ ] PDF document generation
- [ ] Email integration
- [ ] Calendar integration for renewals
- [ ] Mobile app support
- [ ] Multi-tenant support
