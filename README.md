# Software Versions Developer Used to Build
1. Ruby 3.2.2 (https://www.ruby-lang.org/en/downloads/)
2. PosgreSQL 15.3 `brew install postgresql@15` *must install homebrew first if on MacOS/Linux (https://brew.sh/)*
3. Tested in Firefox 117.0 and Chrome 116.0 on MacOS

# How to run application
1. Unzip directory
2. run in terminal `bundle install`
3. populate SQL data *(more information below)*
4. run in terminal `bundle exec ruby app.rb` 
   - may have to specify a port in which case could run, for example `bundle exec ruby app.rb -p 5000`
5. in browser, `localhost:5000` *(or whichever port choosing to run Puma web server on)*
6. Signin with existing user account *(contains seed data)* or signup for new account (no seed data)

## How to populate SQL data for testing
1. install postgresql `brew install postgresql@15`
2. run in command line `createdb test_data`
3. run in command line *(from root project directory)* `psql -d test_data < schema.sql`

## Signin info with prepopulated sql data
email: 'tester@mail.com'
password: '1234#abcD'

# Design Choices
## Note about SQL
As am using the PG gem + not deploying this website, it seemed the most straight-forward for testing and grading purposes to have you, the grader, create a database with the name "test_data" and load the seed data contained in 'schema.sql' into your local postgresql environment.

## Regarding duplication of views and routes
One of my goals was to allow a user to have a page where they could view all logins for all categories (ie all_logins.erb). While I am pleased with the UX result, it did lead to a fair amount of duplication of both routes and views. I could not figure out a better solution such that my forms would be directed to the correct routes and in turn my routes would load the correct views, without this duplication. 

## Regarding Security of User Passwords
I used the bcrypt gem to hash user signin passwords. The nature of this website is to allow a user to store their website/application login information for all of their logins. In a real world scenario, there would be additional security measures in place in order to secure the user's login information. For the scope of this project, this did not seem necessary but I did want to address this potential security vulnerability and list some ways that I might address this in production.

1. Have website only accessible via HTTPS/SSL, for example through Heroku (https://devcenter.heroku.com/articles/ssl)
2. Host database in a secure cloud environment like AWS (https://aws.amazon.com/security/)
3. Encryption of user login data
    - to note... with bcrypt there is no way to decrypt a hashed password. As I wanted to demonstrate an app where a user could view their stored logins information, this was not possible with bcrypt

