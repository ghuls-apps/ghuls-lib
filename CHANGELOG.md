# Changelog
## Version 2
### Version 3.0.1
* Fix NoMethodError on get_organized_repos private function.

### Version 3.0.0
* A more object oriented approach: Ghuls::Lib is now a class, and uses initialize and instance methods instead of a 
bunch of module functions. No methods take the colors hash or the Octokit instance anymore. `calculate_percent` is, 
however, *not* an instance method.

### Version 2.3.3
* Pessimistic version requirements.
* License as MIT.

### Version 2.3.2
* Bump Octokit and StringUtility versions.
* Fix `NoMethodError #to_i_separated on nilClass` error in `#get_random_user` caused by an outdated regex.

### Version 2.3.1
* Fix NoMethodError caused by accessibility keyword overwriting.

### Version 2.3.0
* Remove get_next in favor of the faster array_utility method.
* No longer get random users with 0 repositories.
* Update all dependencies.
  * ruby: 2.2.3 -> 2.3.0
  * octokit: 4.0.1 -> 4.2.0
  * string-utility: 2.6.0 -> 2.6.1
  * net-http-persistent: nil -> 2.9.4
  * faraday-http-cache: nil -> 1.2.2
* Use module_function instead of self.foobar

### Version 2.2.3
* Use Marshal serializer to fix encoding error. This is a faraday-http-cache problem, as described in plataformatec/faraday-http-cache#38 (#8)

### Version 2.2.2
* Fix LoadError by properly requiring faraday-http-cache as a dependency.

### Version 2.2.1
* Fix NameError

### Version 2.2.0
* Use Net/HTTP/Persistent for the Faraday adapter to greatly improve performance, by utilizing persistent HTTP connections to GitHub.
* Refactor most methods to slightly improve their performance, through earlier returns, less variable declarations, quicker methods,
* Caching to improve performance.
* Remove redundant begin blocks.
* Upgrade StringUtility dependency to 2.6.0 for improved performance.

### Version 2.1.2
* get_org_langs and get_user_langs ignore forked repositories again.

### Version 2.1.1
* Fix get_org_langs to work with get_org_repos properly.

### Version 2.1.0
* Refactor get_user_repos to use private method get_organized_repos.
* Refactor get_org_repos to match that of get_user_repos.
* Delete analyze_user and analyze_orgs methods because they are no longer needed.

### Version 2.0.2
* Remove a puts call (oops!)
* Fix analyze methods always returning nil.

### Version 2.0.1
* Actually use the get_user_repos method for what it was originally created for.

### Version 2.0.0
* analyze methods no longer return percentages, to allow for combined data of users and organizations. This also will allow graphic applications (like the web application) to provide byte data rather than two sets of percentages. Prior to this change, the web application shows the percentages provided by GHULS::Lib, as well as the one created by Google Charts.
* New methods to get much more data. Please see docs for detailed information (#5):
  * get_user_repos
  * get_forks_stars_watchers
  * get_followers_following
  * get_issue_pulls
* Improved some styling.

## Version 1
### Version 1.2.1
* Docs are more accurate.
* The analyze_orgs and analyze_user methods no longer call get_user_and_check, because that should be done on the "client" (for example: web or cli) side.
* The analyze_orgs and analyze_user methods no longer return Boolean values. They return nil if the user has no repositories/languages.

### Version 1.2.0
* user_exists? is no longer a thing. Instead, get_user_and_check will return false if the user doesn't exist.
* get_user_and_check now returns a Hash of the user's username and their avatar URL.

### Version 1.1.3
* Fix NoMethodError when an organization has no repositories, or contributors.
* Fix open-ended versioning.

### Version 1.1.2
* Update/create docs for methods.
* Fix the issue that caused a NameError when get_random_user returned a user that no longer exists (#3).

### Version 1.1.1
* Rename lib file again to fix NameError in CLI and web.
* Remove rainbow dependency.

### Version 1.1.0
* Rename lib file.

### Version 1.0.0
* Initial release based on the code from the GHULS CLI application.
