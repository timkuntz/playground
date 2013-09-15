# Be sure to restart your server when you modify this file.

# Your secret key is used for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!

# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
# You can use `rake secret` to generate a secure secret key.

# Make sure your secret_key_base is kept private
# if you're sharing your code publicly.
# Playground::Application.config.secret_key_base = '1396df406d7dc42f07619f090aa2f9cbfb61f41194fa106f2df31841d64aa5a5c63584962f3960388dab8aac571248a575a61929fc9952781b7f841e31f1f810'

require 'securerandom'

def secure_token
  token_file = Rails.root.join('.secret')
  if File.exist?( token_file)
    # Use the existing token.
    File.read( token_file).chomp
  else
    # Generate a new token and store it in token_file.
    token = SecureRandom.hex(64)
    File.write( token_file, token)
    token
  end
end

Playground::Application.config.secret_key_base = secure_token
