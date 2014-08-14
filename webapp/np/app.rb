require 'sinatra'
require 'sinatra/url_for'
require 'erubis'
require 'mysql2-cs-bind'
require 'bcrypt'

require 'ext/object/blank'
require 'formvalidator/lite'
require 'html/fillinform/lite'

set :erb, :escape_html => true

configure do
  set :session_secret, 'session secret'
  enable :sessions
  use Rack::Protection
end

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

  def recent_posts
    recent_posts = [
      {
        'id'       => 1,
        'username' => 'dummy user',
        'stars'    => 10,
        'headline' => 'dummy content hogehogehoggge',
      }
    ]

    # -------------------------------------------------
    # sidebar に表示する最新post一覧を生成してください
    # 件数は最大 load_config[:recent_posts_limit]
    # -------------------------------------------------

    recent_posts
  end

  def u(str)
    URI.escape(str)
  end

end

before do
  @session = session
end

get '/' do
  @recent_posts = recent_posts
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
    @recent_posts = recent_posts
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

  redirect to("/post/#{post_id}")
end

get '/post/:id' do
  post_id = params[:id]

  # ------------------------------------
  # postを表示する機能を実装してください
  # ------------------------------------

  @post = {
    'id'         => post_id,
    'content'    => "dummy content\nfoo\nbar",
    'username'   => 'dummy user',
    'stars'      => 10,
    'created_at' => '2013-04-10 15:26:40',
  }
  @recent_posts = recent_posts

  erb :post
end

post '/star/:id' do
  username = session[:username]
  if username.nil?
    halt 400, 'invalid request'
  end

  post_id = params[:id]
  mysql = connection
  post = mysql.xquery(
    'SELECT id, user_id, content, created_at FROM posts WHERE id=?',
    post_id
  ).first
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

  # -----------------------------
  # ログイン処理を入れてください
  # -----------------------------
  success = true

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
  # --------------------------------------
  # 入力の validate 処理を入れてください
  # username: 必須 2文字以上20文字以下 半角アルファベットと数字のみ
  # password: 必須 2文字以上20文字以下 ASCII のみ
  # --------------------------------------

  # validationでエラーが起きたらフォームを再表示
  if validator.has_error?
    @errors = validator.errors
    body = erb :signup
    return HTML::FillinForm::Lite.new.fill(body, request)
  end

  # validationを通ったのでユーザを作成
  mysql = connection
  mysql.xquery(
    'INSERT INTO users (username, password) VALUES (?, ?)',
    username, password
  )

  session[:username] = username

  redirect to('/')
end
