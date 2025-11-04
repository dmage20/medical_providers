# Base controller for Mission Control — Jobs with authentication
# In development: open access
# In production: requires authentication via Rails 8 authentication system

class MissionControlAuthenticatedController < ApplicationController
  # Skip authentication in development for convenience
  # Require authentication in production
  before_action :require_authentication, unless: -> { Rails.env.development? }

  private

  def require_authentication
    # Uses the Authentication concern from Rails 8 generator
    # If user is not authenticated, redirects to sign in page
    unless authenticated?
      redirect_to new_session_path, alert: "You must be signed in to access Mission Control"
    end
  end
end
