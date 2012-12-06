source 'https://rubygems.org'

gem 'rails', '3.2.6'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'pg'


# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', '~>0.10.2', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

gem 'acts_as_tree'

#use a forked version of mechanize that automatically follows redirects for all verbs with the same verb, as the
#DX sometimes demands. A general purpose HTTP agent is not supposed to do this.
gem 'mechanize', :git => 'git://github.com/medusa-project/mechanize.git'
gem 'logger' #for debugging mechanize interactions
gem 'net-http-digest_auth', :git => 'git://github.com/medusa-project/net-http-digest_auth.git'

gem 'rb-readline'
gem 'ruby-filemagic', :require => 'filemagic'
gem 'uuid'
# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'debugger'

group :development, :test do
  gem 'thin'
end