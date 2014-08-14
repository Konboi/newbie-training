# -*- coding: utf-8 -*-
require 'sinatra'
require 'sinatra/url_for'
require 'erubis'
require 'mysql2-cs-bind'
require 'bcrypt'
require 'json'
require 'redis'
require 'hiredis'

require 'ext/object/blank'
require 'formvalidator/lite'
require 'html/fillinform/lite'

set :erb, :escape_html => true

helpers do
  def load_config
    {
      :database => {
        :host     => '127.0.0.1',
        :port     => '3306',
        :username => 'root',
        :password => '',
        :dbname   => 'test',
      },
      :redis => {
        :host => '127.0.0.1',
        :port => 6379,
      },
      :recent_posts_limit => 100,
    }
  end

  def connection
    config = load_config[:database]
    return $mysql if $mysql

    $mysql = Mysql2::Client.new(
      :host      => config[:host],
      :port      => config[:port],
      :username  => config[:username],
      :password  => config[:password],
      :database  => config[:dbname],
      :reconnect => true,
    )
  end

  def redis_connection
      config =load_config[:redis]
      return $redis if $redis

      $redis = Redis.new(
       :host => config[:host],
       :port => config[:port],
       :driver => :hiredis
      )
  end

  def recent_posts_redis
      redis = redis_connection
      recent_post_redis = redis.get("recent_post")
      recent_post_redis = recent_post_redis ? JSON.parse(recent_post_redis) : recent_posts

      recent_post_redis
  end

  def recent_posts_set_redis

      recent_posts_limit = load_config[:recent_posts_limit]
      mysql = connection
      posts = mysql.xquery(
          "SELECT posts.id as id, posts.user_id as user_id, posts.content as content, users.username as username FROM posts INNER JOIN users ON users.id = posts.user_id ORDER BY posts.created_at DESC LIMIT #{recent_posts_limit}"
      )

      recent_posts = []
      posts.each do |post|
          stars_count = get_star(post['id'])

          recent_posts.push({
              'id'       => post['id'],
              'username' => post['username'],
              'stars'    => stars_count.to_i,
              'headline' => post['content'].slice(0, 30 )
          })
      end

      redis = redis_connection
      redis.set('recent_post', recent_posts.to_json)

      return 1
  end

  def post_redis(post_id)
      redis = redis_connection
      post = redis.get(post_id)

      if post then
          post = JSON.parse(post)
      else
          mysql = connection
          post = mysql.xquery(
              'SELECT posts.id as id, users.id as user_id, posts.content as content, posts.created_at as created_at, users.username as usernmae FROM posts INNER JOIN users ON users.id = posts.user_id WHERE posts.id=?',
              post_id
          ).first
      end
  end

  def get_star(post_id)
      redis = redis_connection
      star_count = redis.get("start_#{post_id}")
      star_count = star_count ? star_count.to_i : 0

      return star_count
  end

  def set_star(post_id,star_count)
      redis = redis_connection
      redis.set("start_#{post_id}", star_count)
  end

  def set_post_redis(post_id)
      redis = redis_connection

      mysql = connection
      post = mysql.xquery(
          'SELECT posts.id as id, users.id as user_id, posts.content as content, posts.created_at as created_at, users.username as usernmae FROM posts INNER JOIN users ON users.id = posts.user_id WHERE posts.id=?',
          post_id
      ).first

      redis.set(post_id, post.to_json)
  end

  def recent_posts
    recent_posts_limit = load_config[:recent_posts_limit]

    ## TODO
    # created_at にindexはる
    mysql = connection
    posts = mysql.xquery(
      "SELECT posts.id as id, posts.user_id as user_id, posts.content as content, users.username as username FROM posts INNER JOIN users ON users.id = posts.user_id ORDER BY posts.created_at DESC LIMIT #{recent_posts_limit}"
    )

    recent_posts = []
    posts.each do |post|
      stars_count = mysql.xquery(
        'SELECT COUNT(id) as count FROM stars WHERE post_id=?',
        post['id']
      )

      recent_posts.push({
        'id'       => post['id'],
        'username' => post['username'],
        'stars'    => stars_count.first['count'],
        'headline' => post['content'].slice(0, 30)
      })
    end

    recent_posts
  end

  def u(str)
    URI.escape(str.to_s)
  end

end

before do
  @session = session
end

get '/' do
  @recent_posts = recent_posts_redis
  @errors       = Hash.new {|h,k| h[k] = {}}

  erb :index
end

post '/post' do
  username = session[:username]
  if username.nil?
    halt 400, 'invalid request'
  end

  validator = FormValidator::Lite.new(request)
  result = validator.check(
    'content', %w( NOT_NULL )
  )

  if result.has_error?
    @recent_posts = recent_posts_redis
    @errors = result.errors
    body = erb :index
    return HTML::FillinForm::Lite.new.fill(body, request)
  end

  mysql = connection
  user = mysql.xquery(
    'SELECT id FROM users WHERE username=?',
    username
  ).first
  user_id = user['id']
  content = params['content']

  mysql.xquery(
    'INSERT INTO posts (user_id, content) VALUES (?, ?)',
    user_id, content
  )
  post_id = mysql.last_id

  set_post_redis(post_id)
  recent_posts_set_redis

  redirect to("/post/#{post_id}")
end

get '/post/:id' do
  post_id = params[:id]

  post = post_redis(post_id)
  if post.blank?
    halt 404, 'Not Found'
  end

  stars_count = get_star(post_id)

  @post = {
    'id'         => post['id'],
    'content'    => post['content'],
    'username'   => post['username'],
    'stars'      => stars_count.to_i,
    'created_at' => post['created_at']
  }
  @recent_posts = recent_posts_redis

  erb :post
end

post '/star/:id' do
  username = session[:username]
  if username.nil?
    halt 400, 'invalid request'
  end

  post_id = params[:id]
  mysql = connection
  post = post_redis(post_id)
  halt 404, '404 Not Found' unless post

  user = mysql.xquery(
    'SELECT id FROM users WHERE username=?',
    username
  ).first
  user_id = user['id']

  mysql.xquery(
    'INSERT INTO stars (post_id, user_id) VALUES(?, ?)',
    post_id, user_id
  )

  stars_count = mysql.xquery(
      'SELECT COUNT(id) as count FROM stars WHERE post_id=?',
      post['id']
  ).first['count']

  set_star(post_id, stars_count)

  redirect to("/post/#{post_id}")
end

get '/signin' do
  @errors = Hash.new {|h,k| h[k] = {} }
  erb :signin
end

get '/signout' do
  session.destroy
  redirect to('/')
end

post '/signin' do
  username = params[:username]
  password = params[:password]

  mysql = connection
  user = mysql.xquery(
    'SELECT password FROM users WHERE username=?',
    username
  ).first

  success = user.present?
  if success
    crypt   = BCrypt::Password.new(user['password'])
    success = (crypt == password)
  end

  if success
    # ログインに成功した場合
    session.clear
    session[:username] = username
    return redirect to('/')
  end

  # ログイン失敗した場合
  validator = FormValidator::Lite.new(request)
  validator.set_error('login', 'FAILED')
  @errors = validator.errors

  erb :signin
end

get '/signup' do
  @errors = Hash.new {|h,k| h[k] = {}}
  erb :signup
end

post '/signup' do
  username = params[:username]
  password = params[:password]

  validator = FormValidator::Lite.new(request)
  result = validator.check(
    'username', [%w(NOT_NULL), ['REGEXP', /\A[a-zA-Z0-9]{2,20}\z/]],
    'password', [%w(NOT_NULL ASCII), %w(LENGTH 2 20)],
    { 'password' => %w(password password_confirm) }, ['DUPLICATION']
  )

  mysql = connection
  user_count = mysql.xquery(
    'SELECT count(*) AS c FROM users WHERE username=?',
    username
  ).first['c']
  if user_count > 0
    validator.set_error('username', 'EXISTS')
  end

  # validationでエラーが起きたらフォームを再表示
  if validator.has_error?
    @errors = validator.errors
    body = erb :signup
    return HTML::FillinForm::Lite.new.fill(body, request)
  end

  salted = BCrypt::Password.create(password).to_s

  # validationを通ったのでユーザを作成
  mysql.xquery(
    'INSERT INTO users (username, password) VALUES (?, ?)',
    username, salted
  )

  session[:username] = username

  redirect to('/')
end
