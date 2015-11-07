require 'octokit'
require 'string-utility'
require 'open-uri'

module GHULS
  module Lib
    # Gets the Octokit and colors for the program.
    # @param opts [Hash] The options to use. The ones that are used by this
    #   method are: :token, :pass, and :user.
    # @return [Hash] A hash containing objects formatted as
    #   { git: Octokit::Client, colors: JSON }
    def self.configure_stuff(opts = {})
      token = opts[:token]
      pass = opts[:pass]
      user = opts[:user]
      gh = Octokit::Client.new(login: user, password: pass) if token.nil?
      gh = Octokit::Client.new(access_token: token) unless token.nil?
      begin
        encode = gh.contents('ozh/github-colors', path: 'colors.json')[:content]
        colors = JSON.parse(Base64.decode64(encode))
      rescue Octokit::Unauthorized
        return false
      end
      { git: gh, colors: colors }
    end

    # Gets the next value in an array.
    # @param single [Any] The current value.
    # @param full [Array] The main array to parse.
    # @return [Any] The next value in the array.
    def self.get_next(single, full)
      full.at(full.index(single) + 1)
    end

    # Gets the user and checks if it exists in the process.
    # @param user [Any] The user ID or name.
    # @param github [Octokit::Client] The instance of Octokit::Client.
    # @return [Hash] Their username and avatar URL.
    # @return [Boolean] False if it does not exist.
    def self.get_user_and_check(user, github)
      begin
        user_full = github.user(user)
      rescue Octokit::NotFound
        return false
      end
      {
        username: user_full[:login],
        avatar: user_full[:avatar_url]
      }
    end

    # Returns the repos in the user's organizations that they have actually
    #   contributed to.
    # @param username [String] See #get_user_and_check
    # @param github [Octokit::Client] See #get_user_and_check
    # @return [Array] All the repository full names that the user has
    #   contributed to.
    def self.get_org_repos(username, github)
      orgs = github.organizations(username)
      repos = []
      orgs.each do |o|
        this_org_repos = github.repositories(o[:login])
        next unless this_org_repos.any?
        repos += this_org_repos
      end
      true_repos = []
      repos.each do |r|
        next if r[:fork]
        contributors = github.contributors(r[:full_name])
        next if contributors.empty?
        contributors.each do |c|
          if c[:login] =~ /^#{username}$/i
            true_repos.push(r[:full_name])
          else
            next
          end
        end
      end
      true_repos
    end

    # Gets the langauges and their bytes for the user.
    # @param username [String] See #get_user_and_check
    # @param github [Octokit::Client] See #get_user_and_check
    # @return [Hash] The languages and their bytes, as formatted as
    #   { :Ruby => 129890, :CoffeeScript => 5970 }
    def self.get_user_langs(username, github)
      repos = github.repositories(username)
      langs = {}
      repos.each do |r|
        next if r[:fork]
        repo_langs = github.languages(r[:full_name])
        repo_langs.each do |l, b|
          if langs[l].nil?
            langs[l] = b
          else
            existing = langs[l]
            langs[l] = existing + b
          end
        end
      end
      langs
    end

    # Gets the languages and their bytes for the user's organizations.
    # @param username [String] See #get_user_and_check
    # @param github [Octokit::Client] See #get_user_and_check
    # @return [Hash] See #get_user_langs
    def self.get_org_langs(username, github)
      org_repos = get_org_repos(username, github)
      langs = {}
      org_repos.each do |r|
        repo_langs = github.languages(r)
        repo_langs.each do |l, b|
          if langs[l].nil?
            langs[l] = b
          else
            existing = langs[l]
            langs[l] = existing + b
          end
        end
      end
      langs
    end

    # Gets the percentage for the given numbers.
    # @param part [Fixnum] The partial value.
    # @param whole [Fixnum] The whole value.
    # @return [Fixnum] The percentage that part is of whole.
    def self.calculate_percent(part, whole)
      (part / whole) * 100
    end

    # Gets the defined color for the language.
    # @param lang [String] The language name.
    # @param colors [Hash] The hash of colors and languages.
    # @return [String] The 6 digit hexidecimal color.
    # @return [Nil] If there is no defined color for the language.
    def self.get_color_for_language(lang, colors)
      if colors[lang].nil? || colors[lang]['color'].nil?
        return StringUtility.random_color_six
      else
        return colors[lang]['color']
      end
    end

    # Gets the percentages for each language in a hash.
    # @param langs [Hash] The language hash obtained by the get_langs methods.
    # @return [Hash] The language percentages formatted as
    #   { Ruby: 50%, CoffeeScript: 50% }
    def self.get_language_percentages(langs)
      total = 0
      langs.each { |_, b| total += b }
      lang_percents = {}
      langs.each do |l, b|
        percent = calculate_percent(b, total.to_f)
        lang_percents[l] = percent.round(2)
      end
      lang_percents
    end

    # Performs the main analysis of the user's organizations.
    # @param username [String] See #get_user_and_check
    # @param github [Octokit::Client] See #get_user_and_check
    # @return [Hash] See #get_language_percentages
    # @return [Nil] If the user does not have any languages.
    def self.analyze_orgs(username, github)
      langs = get_org_langs(username, github)
      return nil if langs.empty?
      get_language_percentages(langs)
    end

    # Performs the main analysis of the user.
    # @param username [String] See #get_user_and_check
    # @param github [Octokit::Client] See #get_user_and_check
    # @return [Hash] See #analyze_orgs
    # @return [Nil] See #analyze_orgs
    def self.analyze_user(username, github)
      langs = get_user_langs(username, github)
      return nil if langs.empty?
      get_language_percentages(langs)
    end

    using StringUtility
    # Gets a random GitHub user that actually has data to analyze.
    #   Must always get a user that exists and has repositories, so it will
    #   go through a loop infinitely until it gets one. Uses the GitHub Search
    #   to find the maximum number of users, which may not be the best way to do
    #   it. However, none of the documented GitHub APIs show that we can get the
    #   total number of GitHub users.
    # @param github [Octokit::Client] See #get_user_and_check
    # @return [Hash] See #get_user_and_check.
    def self.get_random_user(github)
      source = open('https://github.com/search?utf8=%E2%9C%93&q=repos%3A%3E-1' \
                    '&type=Users&ref=searchresults').read
      continue = false
      while continue == false
        userid = rand(source[/Showing (.*?) available users/, 1].to_i_separated)
        user = get_user_and_check(userid, github)
        continue = true if user != false && !get_user_langs(user, github).empty?
      end
      user
    end
  end
end
