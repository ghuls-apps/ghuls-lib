# Changelog
## Version 1
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
