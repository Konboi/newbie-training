require 'spec_helper'

describe 'top' do
  let(:app) { Rack::Builder.parse_file('config.ru').first }

  it 'response collectly' do
    get '/'
    expect(last_response.status).to eq(200)
    expect(last_response.header['Content-Type']).to eq('text/html;charset=utf-8')

    expect(last_response.body).to have_tag('title', text: 'NoPaste')
    expect(last_response.body).to have_tag('div.hero-unit p a',
                                           text: 'Please sign in',
                                           with: {href: '/signin'})
  end
end

describe 'signup' do
  let(:app) { Rack::Builder.parse_file('config.ru').first }

  context 'success' do
    it 'returns html' do
      get '/signup'
      expect(last_response.status).to eq(200)
      expect(last_response.header['Content-Type']).to eq('text/html;charset=utf-8')

      body = last_response.body
      expect(body).to have_tag('h2.form-signin-heading', text: 'Sign up now!')

      expect(body).to have_tag('form.form-signin', with: {method: 'post', action: '/signup'})
      expect(body).to have_tag("form.form-signin input[name='username']")
      expect(body).to have_tag("form.form-signin input[name='password']")
      expect(body).to have_tag("form.form-signin input[name='password_confirm']")
    end

    it 'success to signup' do
      username = "test#{$$}"
      password = "pass#{$$}"

      post '/signup', username:         username,
                      password:         password,
                      password_confirm: password

      expect(last_response.status).to eq(302)
      location = last_response.header['Location']
      expect(location).to eq('http://example.org/')

      get location
      expect(last_response.status).to eq(200)
      expect(last_response.body).to have_tag('p.navbar-text', text: /Logged in as #{Regexp.escape(username)}/)
    end
  end

  context 'validation error' do
    it 'returns "Already exists" error if username is already used' do
      # TODO:
    end
  end
end

describe 'signout' do
  let(:app) { Rack::Builder.parse_file('config.ru').first }

  it 'success to signout' do
    get '/signout'

    expect(last_response.status).to eq(302)
    location = last_response.header['Location']
    expect(location).to eq('http://example.org/')

    get location
    expect(last_response.status).to eq(200)
    expect(last_response.body).to have_tag('p.navbar-text', text: /Sign in/)
  end
end

describe 'signin' do
  let(:app) { Rack::Builder.parse_file('config.ru').first }

  context 'success' do
    it 'returns html' do
      get '/signin'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to have_tag('form.form-signin', with: {method: 'post', action: '/signin'})
      expect(last_response.body).to have_tag("form.form-signin input[name='username']")
      expect(last_response.body).to have_tag("form.form-signin input[name='password']")
    end

    username = 'test$$'
    password = 'pass$$'

    it 'successes to signin' do
      post '/signin', username: username, password: password
      expect(last_response.status).to eq(302)
      expect(last_response.header['Location']).to eq('http://example.org/')

      get last_response.header['Location']
      expect(last_response.status).to eq(200)
      expect(last_response.body).to have_tag('p.navbar-text', text: /Logged in as #{Regexp.escape(username)}/)
    end
  end

  it 'failed' do
    get '/signin'
    expect(last_response.status).to eq(200)

    username = 'test$$'
    post '/signin', username: username,
                    password: 'xxxx'

    expect(last_response.status).to eq(200)
    expect(last_response.body).to have_tag('div.error span.help-inline', text: 'FAILED')
  end
end

describe 'top' do
  let(:app) { Rack::Builder.parse_file('config.ru').first }
  before { post '/signin', username: 'test$$', password: 'pass$$' }

  it 'is logined and has textarea' do
    get '/'
    expect(last_response.body).to have_tag('div.hero-unit form', with: {action: '/post', method: 'post'})
    expect(last_response.body).to have_tag("div.hero-unit form textarea[name='content']")
  end
end
