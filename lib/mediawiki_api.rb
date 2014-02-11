require "mediawiki_api/version"
require "rest-client"

module MediawikiApi
  def create_article username, password, title, content
    # First request is solely to obtain a valid login token in the API response.
    login_token_response = RestClient.post ENV["API_URL"], {:action => "login", :lgname => username, :lgpassword => password, :format => "json", :lgtoken => ""}

    login_token_data = JSON.parse(login_token_response.body)
    login_token = login_token_data["login"]["token"]
    cookie = login_token_response.cookies

    # Second request repeats the first request with the addition of the token (to complete the login).
    complete_login_response = RestClient.post ENV["API_URL"], {:action => "login", :lgname => username, :lgpassword => password, :format => "json", :lgtoken => login_token}, {:cookies => cookie}

    complete_login_data = JSON.parse(complete_login_response.body)
    complete_login_status = complete_login_data["login"]["result"]
    complete_login_cookie = complete_login_response.cookies
    # Merge the two cookie hashes together into one big super-cookie
    cookie = complete_login_cookie.merge(cookie)

    if (complete_login_status != "Success")
      $stderr.puts "There was a problem - login was NOT successful."
    end

    # First request is solely to obtain a valid edit token in the API response.
    edit_token_response = RestClient.post ENV["API_URL"], {:action => "tokens", :type => "edit", :format => "json"}, {:cookies => cookie}

    edit_token_data = JSON.parse(edit_token_response.body)
    edit_token = edit_token_data["tokens"]["edittoken"]

    # Second request repeats the first request with the addition of the token (to complete the article creation).
    complete_edit_response = RestClient.post ENV["API_URL"], {:action => "edit", :title => title, :text => (content + "[[Category:Browsertest article]]"), :summary => "Article created via an API 'edit' call.", :format => "json", :token => edit_token}, {:cookies => cookie}

    complete_edit_data = JSON.parse(complete_edit_response.body)
    complete_edit_status = complete_edit_data["edit"]["result"]

    if (complete_edit_status != "Success")
      $stderr.puts "There was a problem - new article creation was NOT successful."
    end
  end

  def delete_article username, password, title
    unless (ENV["API_URL"])
      puts "API_URL is not defined - make sure to export a value for that variable before running this test."
    end

    # First request is solely to obtain a valid login token in the API response.
    login_token_response = RestClient.post ENV["API_URL"], {
        "format" => "json",
        "action" => "login",
        "lgname" => username,
        "lgpassword" => password,
    }

    login_token_data = JSON.parse(login_token_response.body)
    login_token = login_token_data["login"]["token"]
    cookie = login_token_response.cookies

    # Second request repeats the first request with the addition of the token (to complete the login).
    complete_login_response = RestClient.post ENV["API_URL"], {
      "format" => "json",
      "action" => "login",
      "lgname" => username,
      "lgpassword" => password,
      "lgtoken" => login_token},
      {:cookies => cookie}

    complete_login_data = JSON.parse(complete_login_response.body)
    complete_login_status = complete_login_data["login"]["result"]

    if (complete_login_status != "Success")
      puts "There was a problem - login was NOT successful."
    end

    # First request is solely to obtain a valid delete token in the API response.
    delete_token_response = RestClient.post ENV["API_URL"], {
      "format" => "json",
      "action" => "tokens",
      "type" => "delete",
    },
      {:cookies => cookie}

    delete_token_data = JSON.parse(delete_token_response.body)
    delete_token = delete_token_data["tokens"]["deletetoken"]

    # Second request repeats the first request
    # with the addition of the token (to complete the article creation).
    complete_delete_response = RestClient.post ENV["API_URL"], {
      "format" => "json",
      "action" => "delete",
      "title" => title,
      "token" => delete_token,
      "reason" => "Deleted by browser tests",
    },
      {:cookies => cookie}

    complete_delete_data = JSON.parse(complete_delete_response.body)

    p complete_delete_data if complete_delete_data["error"]
  end

  def create_user login, password
    # First request is solely to obtain a valid token in the API response.
    createaccount_token_response = RestClient.post ENV["API_URL"], {:action => "createaccount", :name => login, :password =>
        password, :format => "json", :token => ""}

    # Session cookie needs to be maintained for both API requests.
    createaccount_token_data = JSON.parse(createaccount_token_response.body)
    cookie = createaccount_token_response.cookies

    createaccount_token = createaccount_token_data["createaccount"]["token"]
    puts createaccount_token

    # Second request repeats the first request with the addition of the token.
    complete_createaccount_response = RestClient.post ENV["API_URL"], {:action => "createaccount", :name => login, :password => password, :format => "json", :token => createaccount_token}, {:cookies => cookie}

    complete_createaccount_data = JSON.parse(complete_createaccount_response.body)
    complete_createaccount_status = complete_createaccount_data["createaccount"]["result"]

    if (complete_createaccount_status != "success")
      $stderr.puts "There was a problem - new user account creation was NOT successful."
    end
  end
end
