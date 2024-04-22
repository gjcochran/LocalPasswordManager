require 'sinatra'
require 'sinatra/content_for'
require 'tilt/erubis'
require 'bcrypt'
require 'securerandom'

require_relative 'database_persistence'

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
  set :erb, :escape_html => true
end

configure(:development) do
  require 'sinatra/reloader'
  also_reload 'database_persistence.rb'
end

############### DEV TESTING #################
def display_session_info
  puts "session id is #{session[:user_id]}"
  puts "session email is #{session[:email]}"
  puts "session url is #{session[:url]}"
  puts "@user_id is #{@user_id}"
  puts "@categories is #{@categories}"
  puts "params is #{params}"
end
################################

helpers do
  def max_items_per_page
    5
  end

  def page_num
    (params[:page] || 1).to_i
  end
  
  def page_offset
    offset = (page_num - 1) * max_items_per_page
  end
  
  def max_total_pages(user_id, category_id=nil)
    count = @storage.items_count(user_id, category_id).to_i
    count = 1 if count.zero?
    (count / max_items_per_page.to_f).ceil
  end

  # sort data by name, alphabetically
  def reverse?(param)
    param == "true"
  end
  
  def prettify(name)
    name.strip.split.map(&:capitalize).join(' ')
  end
end

before do
  @storage = DatabasePersistence.new(logger)
  session[:errors] = []
  @user_id = session[:user_id]
  @categories = @storage.categories_list(@user_id)
end

############### ERRORS #################
def page_error(page, user_id, category_id=nil)
  if page.to_i < 1 || page.to_i > max_total_pages(user_id, category_id)
    session[:errors] << "Invalid page number"
  end
end

def sign_up_unique_error(email)
  if @storage.all_users.any? { |input| input[:email] == email }
    "#{email} is invalid, must be unique."
  end
end

def sign_in_email_error(email)
  users = @storage.all_users
  result = users.select do |hsh|
    email == hsh[:email]
  end
  "Invalid email" if result.empty?
end

def sign_in_password_error(password)
  users = @storage.all_users
  result = users.select do |hsh|
    BCrypt::Password.new(hsh[:password]) == password
  end
  "Invalid password" if result.empty?
end

def login_naming_unique_error(name, id=0)
  @user_id = session[:user_id]
  if @storage.logins_list(@user_id).any? { |input| input[:login_name] == name && input[:id] != id }
    "#{name} is invalid, must be unique."
  end
end

def category_naming_unique_error(name, id=0)
  @user_id = session[:user_id]
  if @storage.categories_list(@user_id).any? { |input| input[:category_name] == name && input[:id] != id }
    "#{name} is invalid, must be unique."
  end
end

def naming_size_error(name)
  if !(1..100).cover? name.size
    "#{name} is invalid, must be between 1 and 100 characters"
  end
end
################################

############### VALIDATION #################
def user_signed_in?(user_id)
  email = @storage.find_email(user_id)
  display_session_info
  user_id.to_s == session[:user_id] && email == session[:email]  
end

def require_valid_user(user_id)
  unless user_signed_in?(user_id)
    session[:url] = request.url
    session[:errors] << "Not signed in or session has expired. Please sign in before proceeding."
    redirect "/"
  end
end

def load_login(index)
  @user_id = session[:user_id]
  login = @storage.find_login(index, @user_id)
  return login if login

  session[:errors] << "The specified login item was not found."
  redirect "/users/#{@user_id}/all_logins"
end
################################

############### INITIAL SIGNIN/SIGNUP #################
get "/" do
  redirect "/signin"
end

not_found do
  session[:errors] << "Page does not exist."
  erb :sign_in, layout: :initial
end

get "/signup" do
  erb :sign_up, layout: :initial
end

post "/signup" do
  email = params[:email]
  password = BCrypt::Password.create(params[:password])

  unique_error = sign_up_unique_error(email)
  size_error = naming_size_error(email)
  errors = [unique_error, size_error].flatten.compact

  if errors.any?
    session[:errors] << errors
    status 422
    erb :sign_up, layout: :initial
  else
    @storage.add_new_user_with_default_categories(email, password)
    session[:user_id] = @storage.find_user_id(email)
    session[:email] = email
    session[:success] = "Welcome #{email}!"
    @user_id = session[:user_id]
    redirect "/users/#{@user_id}/all_logins"
  end
end

get "/signin" do
  erb :sign_in, layout: :initial
end

post "/signin" do
  email = params[:email]
  email_error = sign_in_email_error(email)
  password_error = sign_in_password_error(params[:password])
  errors = [email_error, password_error].flatten.compact

  if errors.any?
    session[:errors] << errors
    status 422
    erb :sign_in, layout: :initial
  else
    session[:user_id] = @storage.find_user_id(email)
    session[:email] = email
    session[:success] = "Welcome back #{email}!"
    @user_id = session[:user_id]
    session[:url] ? (redirect "#{session[:url]}") : (redirect "/users/#{@user_id}/all_logins")
  end
end

post "/users/:user_id/signout" do
  session.delete(:user_id)
  session.delete(:email)
  session.delete(:url)
  session[:success] = "You have been signed out."
  redirect "/"
end
################################

############### LOGINS #################
######## LOGINS - all ##########
# Main page that redirect to after login. View all logins for current user
get "/users/:user_id/all_logins" do
  require_valid_user(params[:user_id])
  @user_id = session[:user_id]
  page = params[:page] || 1
  redirect "/users/#{@user_id}/all_logins?page=1" if page_error(page, @user_id)

  @categories = @storage.categories_list(@user_id)
  if reverse?(params[:reverse])
    @logins = @storage.all_logins_reverse(@user_id, max_items_per_page, page_offset)
  else
    @logins = @storage.all_logins(@user_id, max_items_per_page, page_offset)
  end
  erb :all_logins, layout: :main
end


# Create a new login on all_logins page
get "/users/:user_id/all_logins/new" do
  require_valid_user(params[:user_id])
  @user_id = session[:user_id]
  @category_id = params[:category_id].to_i
  erb :new_login_from_all, layout: :main
end

# Create a new login on all_logins page
post "/users/:user_id/all_logins" do
  require_valid_user(params[:user_id])
  @user_id = session[:user_id]
  @categories = @storage.categories_list(@user_id)

  login_name = prettify(params[:login_name])
  url = params[:url]
  email = params[:email].strip
  username = params[:username].strip
  password = params[:password].strip
  category_id = @storage.find_category_id_from_name(params[:category_name])
  note = params[:note].strip

  if reverse?(params[:reverse])
    @logins = @storage.all_logins_reverse(@user_id, max_items_per_page, page_offset)
  else
    @logins = @storage.all_logins(@user_id, max_items_per_page, page_offset)
  end

  name_unique_error = login_naming_unique_error(login_name)
  name_size_error = naming_size_error(login_name)
  email_size_error = naming_size_error(email)
  username_size_error = naming_size_error(username)
  password_size_error = naming_size_error(password)
  errors = [name_unique_error, name_size_error, email_size_error, username_size_error, password_size_error].flatten.compact
  
  if errors.any?
    session[:errors] << errors
    status 422
    erb :new_login_from_all, layout: :main 
  else
    @storage.create_new_login(login_name, url, email, username, password, category_id, note, @user_id)
    session[:success] = "New login for #{login_name} has been successfully added."
    redirect "/users/#{@user_id}/all_logins"
  end
end

# Edit a login from all_logins page
get "/users/:user_id/all_logins/:login_id/edit" do
  require_valid_user(params[:user_id])
  @user_id = session[:user_id]
  @logins = @storage.all_logins(@user_id, max_items_per_page, page_offset)
  @login_id = params[:login_id].to_i
  @login = load_login(@login_id)
  @category_id = @storage.find_category_id(@login_id)
  erb :edit_login_from_all, layout: :main
end

# Edit a login from all_logins page
post "/users/:user_id/all_logins/:login_id" do
  require_valid_user(params[:user_id])
  @user_id = session[:user_id]
  @logins = @storage.all_logins(@user_id, max_items_per_page, page_offset)
  @login_id = params[:login_id].to_i
  @login = load_login(@login_id)
  @category_id = @storage.find_category_id(@login_id)
  
  login_name = prettify(params[:login_name])
  url = params[:url]
  email = params[:email].strip
  username = params[:username].strip
  password = params[:password].strip
  category_id = @storage.find_category_id_from_name(params[:category_name])
  note = params[:note].strip

  name_unique_error = login_naming_unique_error(login_name, @login_id)
  name_size_error = naming_size_error(login_name)
  email_size_error = naming_size_error(email)
  username_size_error = naming_size_error(username)
  password_size_error = naming_size_error(password)
  errors = [name_unique_error, name_size_error, email_size_error, username_size_error, password_size_error].flatten.compact
  
  if errors.any?
    session[:errors] << errors
    status 422
    erb :edit_login_from_all, layout: :main 
  else
    @storage.update_login(@login_id, login_name, url, email, username, password, category_id, note, @user_id)
    session[:success] = "Login item for #{login_name} has been successfully updated."
    redirect "/users/#{@user_id}/all_logins"
  end
end

# Delete a login from all_logins page
post "/users/:user_id/all_logins/:login_id/delete" do
  require_valid_user(params[:user_id])
  @user_id = session[:user_id]
  @login_id = params[:login_id].to_i
  @category_id = @storage.find_category_id(@login_id)
  
  @storage.delete_login(@login_id, @user_id)
  
  session[:success] = "The login has been deleted."
  redirect "/users/#{@user_id}/all_logins"
end
##################
######## LOGINS - by category ##########
# view all users' logins per category
get "/users/:user_id/categories/:category_id/logins" do
  require_valid_user(params[:user_id])
  @user_id = session[:user_id]
  @category_id = params[:category_id]
  page = params[:page] || 1
  redirect "/users/#{@user_id}/categories/#{@category_id}/logins?page=1" if page_error(page, @user_id, @category_id)
  
  if reverse?(params[:reverse])
    @logins = @storage.all_logins_for_category_reverse(@user_id, @category_id, max_items_per_page, page_offset)
  else
    @logins = @storage.all_logins_for_category(@user_id, @category_id, max_items_per_page, page_offset)
  end
  erb :category, layout: :main
end

# create a new login from a category page
get "/users/:user_id/categories/:category_id/logins/new" do
  require_valid_user(params[:user_id])
  @user_id = session[:user_id]
  @category_id = params[:category_id].to_i
  erb :new_login_from_category, layout: :main
end

# create a new login from a category page
post "/users/:user_id/categories/:category_id/logins" do
  require_valid_user(params[:user_id])
  @user_id = session[:user_id]
  @categories = @storage.categories_list(@user_id)
  @category_id = params[:category_id].to_i

  login_name = prettify(params[:login_name])
  url = params[:url]
  email = params[:email].strip
  username = params[:username].strip
  password = params[:password].strip
  category_name = params[:category_name].strip
  note = params[:note].strip
  
  category_id = @storage.find_category_id_from_name(category_name)
  
  if reverse?(params[:reverse])
    @logins = @storage.all_logins_for_category_reverse(@user_id, @category_id, max_items_per_page, page_offset)
  else
    @logins = @storage.all_logins_for_category(@user_id, @category_id, max_items_per_page, page_offset)
  end

  name_unique_error = login_naming_unique_error(login_name) 
  name_size_error = naming_size_error(login_name)
  email_size_error = naming_size_error(email)
  username_size_error = naming_size_error(username)
  password_size_error = naming_size_error(password)
  errors = [name_unique_error, name_size_error, email_size_error, username_size_error, password_size_error].flatten.compact
  
  if errors.any?
    session[:errors] << errors
    status 422
    erb :new_login_from_category, layout: :main 
  else
    @storage.create_new_login(login_name, url, email, username, password, category_id, note, @user_id)
    session[:success] = "New login for #{login_name} has been successfully added."
    redirect "/users/#{@user_id}/categories/#{@category_id}/logins"
  end
end

# Edit a login from a category page
get "/users/:user_id/categories/:category_id/logins/:login_id/edit" do
  require_valid_user(params[:user_id])
  @user_id = session[:user_id]
  @login_id = params[:login_id].to_i
  @login = load_login(@login_id)
  @category_id = @storage.find_category_id(@login_id)
  @logins = @storage.all_logins_for_category(@user_id, @category_id, max_items_per_page, page_offset)
  erb :edit_login_from_category, layout: :main
end

# Edit a login from a category page
post "/users/:user_id/categories/:category_id/logins/:login_id" do
  require_valid_user(params[:user_id])
  @user_id = session[:user_id]
  @login_id = params[:login_id].to_i
  @login = load_login(@login_id)
  @category_id = params[:category_id]
  @logins = @storage.all_logins_for_category(@user_id, @category_id, max_items_per_page, page_offset)
  
  login_name = prettify(params[:login_name])
  url = params[:url]
  email = params[:email].strip
  username = params[:username].strip
  password = params[:password].strip
  category_id = @storage.find_category_id_from_name(params[:category_name])
  note = params[:note].strip

  name_unique_error = login_naming_unique_error(login_name, @login_id)
  name_size_error = naming_size_error(login_name)
  email_size_error = naming_size_error(email)
  username_size_error = naming_size_error(username)
  password_size_error = naming_size_error(password)
  errors = [name_unique_error, name_size_error, email_size_error, username_size_error, password_size_error].flatten.compact
  
  if errors.any?
    session[:errors] << errors
    status 422
    erb :edit_login_from_category, layout: :main 
  else
    @storage.update_login(@login_id, login_name, url, email, username, password, category_id, note, @user_id)
    session[:success] = "Login item for #{login_name} has been successfully updated."
    redirect "/users/#{@user_id}/categories/#{@category_id}/logins"
  end
end

# Delete a login from a category page
post "/users/:user_id/categories/:category_id/logins/:login_id/delete" do
  require_valid_user(params[:user_id])
  @user_id = session[:user_id]
  @login_id = params[:login_id].to_i
  @category_id = params[:category_id].to_i
  
  @storage.delete_login(@login_id, @user_id)
  
  session[:success] = "The login has been deleted."
  redirect "/users/#{@user_id}/categories/#{@category_id}/logins"
end
##################
################################

############### CATEGORIES #################

# create a new category
get "/users/:user_id/categories/new" do
  require_valid_user(params[:user_id])
  @user_id = session[:user_id]
  erb :new_category, layout: :main
end

# create a new category
post "/users/:user_id/categories" do
  require_valid_user(params[:user_id])
  @user_id = session[:user_id]

  category_name = prettify(params[:category_name])
  
  name_unique_error = category_naming_unique_error(category_name)
  name_size_error = naming_size_error(category_name)
  errors = [name_unique_error, name_size_error].flatten.compact
  
  if errors.any?
    session[:errors] << errors
    status 422
    erb :new_category, layout: :main 
  else
    @storage.create_new_category(category_name, @user_id)
    category_id = @storage.find_category_id_from_name(category_name)
    session[:success] = "New login for #{category_name} has been successfully added."
    redirect "/users/#{@user_id}/categories/#{category_id}/logins"
  end
end

# Edit a category
get "/users/:user_id/categories/:category_id/edit" do
  require_valid_user(params[:user_id])
  @user_id = session[:user_id]
  @category_id = params[:category_id].to_i
  @category_name = @storage.find_category_name_from_id(@category_id)
  erb :edit_category, layout: :main
end

# Edit a category
post "/users/:user_id/categories/:category_id" do
  require_valid_user(params[:user_id])
  @user_id = session[:user_id].to_i
  @category_id = params[:category_id].to_i
    
  category_name = prettify(params[:category_name])
  
  name_unique_error = category_naming_unique_error(category_name, @category_id)
  name_size_error = naming_size_error(category_name)
  errors = [name_unique_error, name_size_error].flatten.compact
  
  if errors.any?
    session[:errors] << errors
    status 422
    erb :edit_category, layout: :main 
  else
    @storage.update_category(@category_id, category_name, @user_id)
    session[:success] = "Login item for #{category_name} has been successfully updated."
    redirect "/users/#{@user_id}/categories/#{@category_id}/logins"
  end
end

# Delete a category
post "/users/:user_id/categories/:category_id/delete" do
  require_valid_user(params[:user_id])
  @user_id = session[:user_id]
  @category_id = params[:category_id].to_i
  
  @storage.delete_category(@category_id, @user_id)
  
  session[:success] = "The category has been deleted."
  redirect "/users/#{@user_id}/all_logins"
end
################################

############### USERS #################
# View all user settings (ie signin email/password)
get "/users/:user_id/settings" do
  require_valid_user(params[:user_id])
  erb :settings, layout: :main
end

# Edit user credentials - email
get "/users/:user_id/edit/email" do 
  require_valid_user(params[:user_id])
  @user_id = session[:user_id].to_i
  @user_email = @storage.find_email(@user_id)
  erb :edit_user_email, layout: :main
end

# Edit user credentials - email
post "/users/:user_id/email" do
  require_valid_user(params[:user_id])
  @user_id = session[:user_id].to_i
  @user_email = @storage.find_email(@user_id)
    
  email = params[:email]
  unique_error = sign_up_unique_error(email)
  size_error = naming_size_error(email)
  errors = [unique_error, size_error].flatten.compact

  if errors.any?
    session[:errors] << errors
    status 422
    erb :settings, layout: :initial
  else
    @storage.update_user_email(@user_id, email)
    session[:email] = email
    session[:success] = "User credentials for #{email} have been updated."
    redirect "/users/#{@user_id}/all_logins"
  end
end

# Edit user credentials - password
get "/users/:user_id/edit/password" do 
  require_valid_user(params[:user_id])
  @user_id = session[:user_id].to_i
  erb :edit_user_password, layout: :main
end

# Edit user credentials - password
post "/users/:user_id/password" do
  require_valid_user(params[:user_id])
  @user_id = session[:user_id].to_i
    
  password = BCrypt::Password.create(params[:password])

  @storage.update_user_password(@user_id, password)
  session[:success] = "User credentials for #{email} have been updated."
  redirect "/users/#{@user_id}/all_logins"
end

# Delete a user account
post "/users/:user_id/delete" do
  require_valid_user(params[:user_id])
  @user_id = session[:user_id]
  
  @storage.delete_user(@user_id)
  
  session[:success] = "Your user account has been deleted."
  redirect "/"
end
################################













