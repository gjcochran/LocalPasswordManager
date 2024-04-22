CREATE TABLE users (
  id serial PRIMARY KEY,
  email varchar(100) UNIQUE NOT NULL,
  password varchar(100) NOT NULL
);

CREATE TABLE logins (
    id serial PRIMARY KEY,
    login_name varchar(100) NOT NULL,
    url text NOT NULL,
    email varchar(100) NOT NULL,
    username varchar(100) NOT NULL,
    password varchar(100) NOT NULL,
    category_id INT NOT NULL,
    note text,
    user_id INT NOT NULL
);

CREATE TABLE categories (
    id serial PRIMARY KEY,
    category_name varchar(100) NOT NULL,
    user_id INT NOT NULL
);


ALTER TABLE logins 
            ADD FOREIGN KEY (category_id) 
            REFERENCES categories (id);

ALTER TABLE logins 
            ADD FOREIGN KEY (user_id) 
            REFERENCES users (id);

ALTER TABLE categories
            ADD FOREIGN KEY (user_id) 
            REFERENCES users (id);

INSERT INTO users (email, password) VALUES
('tester@mail.com', '$2a$12$jsFqMcn4omkmUD3qNz8kDOQfExkD.jQJjODRHV478EejFrxtsoj8G');

INSERT INTO categories (category_name, user_id) VALUES
('Shopping', 1), ('Utilities', 1), ('Travel', 1), ('Entertainment', 1), ('Finance', 1);

INSERT INTO logins (login_name, url, email, username, password, category_id, note, user_id) VALUES
('Netflix', 'https://www.netflix.com', 'tester@mail.com', 'tester', 'ABcd$321', 4, 'sample note text', 1),
('Chase', 'https://www.chase.com', 'tester@mail.com', 'tester', 'ABcd$321', 5, 'sample note text', 1),
('Gmail', 'https://mail.google.com', 'tester@mail.com', 'tester', 'ABcd$321', 2, 'sample note text', 1),
('Gap', 'https://www.gap.com', 'tester@mail.com', 'tester', 'ABcd$321', 1, 'sample note text', 1),
('Wells Fargo', 'https://www.wellsfargo.com', 'tester@mail.com', 'tester', 'ABcd$321', 5, 'sample note text', 1),
('Bank of America', 'https://www.bankofamerica.com', 'tester@mail.com', 'tester', 'ABcd$321', 5, 'sample note text', 1),
('Venmo', 'https://venmo.com', 'tester@mail.com', 'tester', 'ABcd$321', 5, 'sample note text', 1),
('PNC', 'https://www.pnc.com', 'tester@mail.com', 'tester', 'ABcd$321', 5, 'sample note text', 1),
('US Bank', 'https://www.usbank.com', 'tester@mail.com', 'tester', 'ABcd$321', 5, 'sample note text', 1),
('United Airlines', 'https://www.united.com', 'tester@mail.com', 'tester', 'ABcd$321', 3, 'sample note text', 1),
('Delta Airlines', 'https://www.delta.com', 'tester@mail.com', 'tester', 'ABcd$321', 3, 'sample note text', 1),
('Southwest Airlines', 'https://www.southwest.com', 'tester@mail.com', 'tester', 'ABcd$321', 3, 'sample note text', 1),
('Skyscanner', 'https://www.skyscanner.com', 'tester@mail.com', 'tester', 'ABcd$321', 3, 'sample note text', 1),
('Hopper', 'https://www.hopper.com', 'tester@mail.com', 'tester', 'ABcd$321', 3, 'sample note text', 1),
('Alaska Airlines', 'https://www.alaskaair.com', 'tester@mail.com', 'tester', 'ABcd$321', 3, 'sample note text', 1),
('IHG', 'https://www.ihg.com', 'tester@mail.com', 'tester', 'ABcd$321', 3, 'sample note text', 1),
('Rhone', 'https://www.rhone.com', 'tester@mail.com', 'tester', 'ABcd$321', 1, 'sample note text', 1),
('Lululemon', 'http://shop.lululemon.com', 'tester@mail.com', 'tester', 'ABcd$321', 1, 'sample note text', 1),
('Costco', 'http://www.costco.com', 'tester@mail.com', 'tester', 'ABcd$321', 1, 'sample note text', 1),
('Best Buy', 'http://www.bestbuy.com', 'tester@mail.com', 'tester', 'ABcd$321', 1, 'sample note text', 1),
('Barnes & Noble', 'http://www.barnesandnoble.com', 'tester@mail.com', 'tester', 'ABcd$321', 1, 'sample note text', 1),
('Amazon', 'http://www.amazon.com', 'tester@mail.com', 'tester', 'ABcd$321', 1, 'sample note text', 1),
('Hulu', 'http://www.gap.com', 'tester@mail.com', 'tester', 'ABcd$321', 4, 'sample note text', 1),
('Cinemark', 'http://www.cinemark.com', 'tester@mail.com', 'tester', 'ABcd$321', 4, 'sample note text', 1),
('Disney+', 'http://www.disneyplus.com', 'tester@mail.com', 'tester', 'ABcd$321', 4, 'sample note text', 1),
('Apple', 'http://www.icloud.com', 'tester@mail.com', 'tester', 'ABcd$321', 2, 'sample note text', 1);
