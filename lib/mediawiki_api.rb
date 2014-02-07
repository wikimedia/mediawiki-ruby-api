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
end
