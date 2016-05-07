require 'octokit'
require 'string-utility'
require 'open-uri'
require 'faraday-http-cache'

module GHULS
  class Lib
    # @return [Octokit::Client] The octokit instance.
    attr_reader :octokit

    # @return [Hash<String, Hash<String, String>] The colors for each GitHub valid lang.
    # The keys are the language name strings, and the values are hashes. The value hash contains a 'color' and 'url'.
    # The value hash color might be nil. Code expecting nil.
    attr_reader :colors

    # Gets the Octokit and colors for the program.
    # @param opts [Hash] The options to use. The ones that are used by this
    #   method are: :token, :pass, and :user.
    # @return [Hash] A hash containing objects formatted as
    #   { git: Octokit::Client, colors: JSON }
    def initialize(opts = {})
      token = opts[:token]
      pass = opts[:pass]
      user = opts[:user]
      gh_options = token.nil? ? { login: user, password: pass } : { access_token: token }
      gh = Octokit::Client.new(gh_options)
      stack = Faraday::RackBuilder.new do |builder|
        builder.use Faraday::HttpCache, shared_cache: false, serializer: Marshal
        builder.use Octokit::Response::RaiseError
        builder.adapter :net_http_persistent
      end
      gh.middleware = stack
      encode = gh.contents('ozh/github-colors', path: 'colors.json')[:content]
      @octokit = gh
      @colors = JSON.parse(Base64.decode64(encode))
    end

    # Gets the user and checks if it exists in the process.
    # @param user [Any] The user ID or name.
    # @return [Hash] Their username and avatar URL.
    # @return [Boolean] False if it does not exist.
    def get_user_and_check(user)
      user_full = @octokit.user(user)
      {
        username: user_full[:login],
        avatar: user_full[:avatar_url]
      }
    rescue Octokit::NotFound
      return false
    end

    # Returns the repos in the user's organizations that they have actually
    #   contributed to, organized by forks, privates, publics, and mirrors.
    # @param username [String] See #get_user_and_check
    # @return [Array] All the repository full names that the user has
    #   contributed to.
    def get_org_repos(username)
      orgs = @octokit.organizations(username)
      repos = []
      orgs.each do |o|
        this_org_repos = @octokit.repositories(o[:login])
        next unless this_org_repos.any?
        repos.concat(this_org_repos)
      end
      true_repos = []
      repos.each do |r|
        contributors = @octokit.contributors(r[:full_name])
        next if contributors.empty?
        contributors.each do |c|
          if c[:login] =~ /^#{username}$/i
            true_repos << r
          else
            next
          end
        end
      end
      get_organized_repos(true_repos)
    end

    # Gets the user's repositories organized by whether they are forks,
    # private, public, or mirrors.
    # @param username [String] See #get_user_and_check
    # @return [Hash] All the repositories under the user's account.
    def get_user_repos(username)
      get_organized_repos(@octokit.repositories(username))
    end

    # Gets the number of forkers, stargazers, and watchers.
    # @param repository [String] The full repository name.
    # @return [Hash] The forks, stars, and watcher count.
    def get_forks_stars_watchers(repository)
      {
        forks: @octokit.forks(repository).length,
        stars: @octokit.stargazers(repository).length,
        watchers: @octokit.subscribers(repository).length
      }
    end

    # Gets the number of followers and users followed by the user.
    # @param username [String] See #get_user_and_check
    # @return [Hash] The number of following and followed users.
    def get_followers_following(username)
      {
        following: @octokit.following(username).length,
        followers: @octokit.followers(username).length
      }
    end

    # Gets the number of closed/open issues and
    # closed (without merge)/open/merged pull requests for a repository
    # @param repository [String] See #get_forks_stars_watchers
    # @return [Hash] The number of issues and pulls.
    def get_issues_pulls(repository)
      issues = @octokit.list_issues(repository, state: 'all')
      pulls = @octokit.pull_requests(repository, state: 'all')
      issues_open = 0
      issues_closed = 0
      pulls_open = 0
      pulls_closed = 0
      pulls_merged = 0
      issues.each do |i|
        issues_open += 1 if i['state'] == 'open'
        issues_closed += 1 if i['state'] == 'closed'
      end
      pulls.each do |p|
        pulls_open += 1 if p['state'] == 'open'
        if p['state'] == 'closed'
          pulls_merged += 1 unless p['merged_at'].nil?
          pulls_closed += 1 if p['merged_at'].nil?
        end
      end

      {
        issues: {
          closed: issues_closed,
          open: issues_open
        },
        pulls: {
          closed: pulls_closed,
          open: pulls_open,
          merged: pulls_merged
        }
      }
    end

    # Gets the langauges and their bytes for the user.
    # @param username [String] See #get_user_and_check
    # @return [Hash] The languages and their bytes, as formatted as
    #   { :Ruby => 129890, :CoffeeScript => 5970 }
    def get_user_langs(username)
      repos = get_user_repos(username)
      langs = {}
      repos[:public].each do |r|
        next if repos[:forks].include? r
        repo_langs = @octokit.languages(r)
        repo_langs.each do |l, b|
          if langs[l].nil?
            langs[l] = b
          else
            langs[l] += b
          end
        end
      end
      langs
    end

    # Gets the languages and their bytes for the user's organizations.
    # @param username [String] See #get_user_and_check
    # @return [Hash] See #get_user_langs
    def get_org_langs(username)
      org_repos = get_org_repos(username)
      langs = {}
      org_repos[:public].each do |r|
        next if org_repos[:forks].include? r
        repo_langs = @octokit.languages(r)
        repo_langs.each do |l, b|
          if langs[l].nil?
            langs[l] = b
          else
            langs[l] += b
          end
        end
      end
      langs
    end

    # Gets the defined color for the language.
    # @param lang [String] The language name.
    # @return [String] The 6 digit hexidecimal color.
    # @return [Nil] If there is no defined color for the language.
    def get_color_for_language(lang)
      color_lang = @colors[lang]
      color = color_lang['color']
      if color_lang.nil? || color.nil?
        return StringUtility.random_color_six
      else
        return color
      end
    end

    # Gets the percentages for each language in a hash.
    # @param langs [Hash] The language hash obtained by the get_langs methods.
    # @return [Hash] The language percentages formatted as
    #   { Ruby: 50%, CoffeeScript: 50% }
    def get_language_percentages(langs)
      total = 0
      langs.each { |_, b| total += b }
      lang_percents = {}
      langs.each do |l, b|
        percent = calculate_percent(b, total.to_f)
        lang_percents[l] = percent.round(2)
      end
      lang_percents
    end

    using StringUtility

    # Gets a random GitHub user that actually has data to analyze.
    #   Must always get a user that exists and has repositories, so it will
    #   go through a loop infinitely until it gets one. Uses the GitHub Search
    #   to find the maximum number of users, which may not be the best way to do
    #   it. However, none of the documented GitHub APIs show that we can get the
    #   total number of GitHub users.
    # @return [Hash] See #get_user_and_check.
    def get_random_user
      source = open('https://github.com/search?utf8=%E2%9C%93&q=repos%3A%3E0' \
                    '&type=Users&ref=searchresults').read
      continue = false
      until continue
        # Really, GitHub? ’ and not '?
        max = source[/We['’]ve found (.*?) users/] || source[/Showing (.*?) available users/]
        userid = rand(max.to_i_separated)
        user = get_user_and_check(userid)
        continue = true if user != false && !get_user_langs(user).empty?
      end
      # noinspection RubyScope
      user
    end

    # Gets the percentage for the given numbers.
    # @param part [Any] The partial value. Must implement #to_f, or be a Float.
    # @param whole [Any] The whole value. Must implement #to_f, or be a Float.
    # @return [Float] The percentage that part is of whole.
    def self.calculate_percent(part, whole)
      (part.to_f / whole.to_f) * 100
    end

    private

    # Gets the organized repository hash for the main repository hash given
    # by Octokit::Client#repositories
    # @param repos [Hash] The repository hash given by Octokit
    # @return [Hash] An organizeed hash divided into public, forked, mirrored,
    # and private repos.
    def get_organized_repos(repos)
      forks = []
      publics = []
      mirrors = []
      privates = []
      repos.each do |r|
        repo_name = r[:full_name]
        forks << repo_name if r[:fork]

        if r[:private]
          privates << repo_name
        else
          publics << repo_name
        end

        mirrors << repo_name unless r[:mirror_url].nil?
      end

      {
        public: publics,
        forks: forks,
        mirrors: mirrors,
        privates: privates
      }
    end
  end
end
