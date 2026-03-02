json.extract! user, :id, :oauth_id, :email, :name, :picture, :created_at, :updated_at
json.url user_url(user, format: :json)
