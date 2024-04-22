require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: "test_data")
    @logger = logger
  end
  
  ############### DEV TESTING #################
  # debugging method to see sql queries in terminal (from LS)
  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end
  ################################

  def extract(query_result)
    query_result.values.flatten.first
  end

  ############### LOGINS #################
  def find_login(index, user_id)
    sql = "SELECT * FROM logins WHERE id = $1 AND user_id = $2"
    result = query(sql, index, user_id)
    
    tuple = result.first
    {
      id: tuple["id"].to_i,
      login_name: tuple["login_name"],
      url: tuple["url"],
      email: tuple["email"],
      username: tuple["username"],
      password: tuple["password"],
      category_id: tuple["category_id"],
      note: tuple["note"],
    }
  end

  def items_count(user_id, category_id)
    if category_id
      sql = "SELECT COUNT(id) FROM logins WHERE user_id = $1 AND category_id = $2"
      extract(query(sql, user_id, category_id))
    else
      sql = "SELECT COUNT(id) FROM logins WHERE user_id = $1"
      extract(query(sql, user_id))
    end
  end
  
  def logins_list(user_id)
    sql = "SELECT * FROM logins WHERE user_id = $1"
    result = query(sql, user_id)

    result.map do |tuple|
      category_id = tuple["category_id"]
      category_sql = "SELECT category_name FROM categories WHERE id = $1"
      category_result = query(category_sql, category_id)
      {
        id: tuple["id"].to_i,
        login_name: tuple["login_name"],
        url: tuple["url"],
        email: tuple["email"],
        username: tuple["username"],
        password: tuple["password"],
        category: extract(category_result),
        note: tuple["note"],
      }
    end
  end

  def all_logins(user_id, limit, offset)
    sql = "SELECT * FROM logins WHERE user_id = $1 ORDER BY login_name ASC LIMIT $2 OFFSET $3"
    result = query(sql, user_id, limit, offset)

    result.map do |tuple|
      category_id = tuple["category_id"]
      category_sql = "SELECT category_name FROM categories WHERE id = $1"
      category_result = query(category_sql, category_id)
      {
        id: tuple["id"].to_i,
        login_name: tuple["login_name"],
        url: tuple["url"],
        email: tuple["email"],
        username: tuple["username"],
        password: tuple["password"],
        category: extract(category_result),
        note: tuple["note"],
      }
    end
  end

  def all_logins_reverse(user_id, limit, offset)
    sql = "SELECT * FROM logins WHERE user_id = $1 ORDER BY login_name DESC LIMIT $2 OFFSET $3"
    result = query(sql, user_id, limit, offset)

    result.map do |tuple|
      category_id = tuple["category_id"]
      category_sql = "SELECT category_name FROM categories WHERE id = $1"
      category_result = query(category_sql, category_id)
      {
        id: tuple["id"].to_i,
        login_name: tuple["login_name"],
        url: tuple["url"],
        email: tuple["email"],
        username: tuple["username"],
        password: tuple["password"],
        category: extract(category_result),
        note: tuple["note"],
      }
    end
  end

  def all_logins_for_category(user_id, category_id, limit, offset)
    sql = "SELECT * FROM logins WHERE user_id = $1 AND category_id = $2 ORDER BY login_name ASC LIMIT $3 OFFSET $4"
    result = query(sql, user_id, category_id, limit, offset)

    result.map do |tuple|
      {
        id: tuple["id"].to_i,
        login_name: tuple["login_name"],
        url: tuple["url"],
        email: tuple["email"],
        username: tuple["username"],
        password: tuple["password"],
        note: tuple["note"],
      }
    end
  end

  def all_logins_for_category_reverse(user_id, category_id, limit, offset)
    sql = "SELECT * FROM logins WHERE user_id = $1 AND category_id = $2 ORDER BY login_name DESC LIMIT $3 OFFSET $4"
    result = query(sql, user_id, category_id, limit, offset)

    result.map do |tuple|
      {
        id: tuple["id"].to_i,
        login_name: tuple["login_name"],
        url: tuple["url"],
        email: tuple["email"],
        username: tuple["username"],
        password: tuple["password"],
        note: tuple["note"],
      }
    end
  end

  def create_new_login(login_name, url, email, username, password, category_id, note, user_id)
    sql = "INSERT INTO logins (login_name, url, email, username, password, category_id, note, user_id) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)"
    query(sql, login_name, url, email, username, password, category_id, note, user_id)
  end
  
  def update_login(id, login_name, url, email, username, password, category_id, note, user_id)
    sql = "UPDATE logins SET (login_name, url, email, username, password, category_id, note) = ($2, $3, $4, $5, $6, $7, $8) WHERE id = $1 AND user_id = $9"
    query(sql, id, login_name, url, email, username, password, category_id, note, user_id)
  end

  def delete_login(login_id, user_id)
    sql = "DELETE FROM logins WHERE id = $1 AND user_id = $2"
    query(sql, login_id, user_id)
  end
  ################################
  ############### CATEGORIES #################
  def categories_list(user_id)
    sql = "SELECT * FROM categories WHERE user_id = $1"
    result = query(sql, user_id)
    result.map do |tuple|
      {
        id: tuple["id"].to_i,
        category_name: tuple["category_name"],
      }
    end
  end

  def find_category_id(login_id)
    sql = "SELECT category_id FROM logins WHERE id = $1"
    result = query(sql, login_id)
    extract(result)
  end

  def find_category_id_from_name(category_name)
    sql = "SELECT id FROM categories WHERE category_name = $1"
    extract(query(sql, category_name)).to_i
  end

  def find_category_name_from_id(category_id)
    sql = "SELECT category_name FROM categories WHERE id = $1"
    extract(query(sql, category_id))
  end

  def create_new_category(category_name, user_id)
    sql = "INSERT INTO categories (category_name, user_id) VALUES ($1, $2)"
    query(sql, category_name, user_id)
  end
  
  def update_category(id, category_name, user_id)
    sql = "UPDATE categories SET category_name = $1 WHERE id = $2 AND user_id = $3"
    query(sql, category_name, id, user_id)
  end

  def delete_category(category_id, user_id)
    query("DELETE FROM logins WHERE category_id = $1 AND user_id = $2", category_id, user_id)
    query("DELETE FROM categories WHERE id = $1 and user_id = $2", category_id, user_id)
  end
  ################################
  ############### USERS #################
  def all_users
    sql = "SELECT * FROM users"
    result = query(sql)

    result.map do |tuple|
      {
        id: tuple["id"].to_i,
        email: tuple["email"],
        password: tuple["password"],
      }
    end
  end

  def add_new_user_with_default_categories(email, password)
    sql = "INSERT INTO users (email, password) VALUES
    ($1, $2)"
    query(sql, email, password)
    user_id = find_user_id(email)
    add_default_categories(user_id)
  end

  def add_default_categories(user_id)
    sql = "INSERT INTO categories (category_name, user_id) VALUES
    ('Shopping', $1), ('Utilities', $1), ('Travel', $1), ('Entertainment', $1), ('Finance', $1);"
    query(sql, user_id)
  end

  def find_user_id(email)
    sql = "SELECT id FROM users WHERE email = $1"
    result = query(sql, email)
    extract(result)
  end

  def find_email(user_id)
    sql = "SELECT email FROM users WHERE id = $1"
    result = query(sql, user_id)
    extract(result)
  end

  def update_user_email(user_id, email)
    sql = "UPDATE users SET email = $2 WHERE id = $1"
    query(sql, user_id, email)
  end

  def update_user_password(user_id, password)
    sql = "UPDATE users SET password) = $2 WHERE id = $1"
    query(sql, user_id, password)
  end

  def delete_user(user_id)
    query("DELETE FROM logins WHERE user_id = $1", user_id)
    query("DELETE FROM categories WHERE user_id = $1", user_id)
    query("DELETE FROM users WHERE id = $1", user_id)
  end
  ################################
end
