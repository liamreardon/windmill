<p><img src="https://github.com/liamreardon/windmill/blob/master/windmill_banner.png" alt="windmill"></p>

`windmill` is a simplified video-sharing social network built using [Swift 5](https://developer.apple.com/swift/) and [Go](https://golang.org/), where users can record, edit and post looping short-form videos.

|  | Features |
|:---------:|:---------------------------------------------------------------|
| :video_camera: | Record "TikTok" style looping videos |  
| :pencil2: | Add custom text and captions to your videos |
| :bust_in_silhouette: | Create an account and customize your profile |
| :green_heart: | Follow friends and like their videos | 
| :newspaper: | Browse newsfeed of videos from users you follow | 
| :handshaking: | View activity feed to see who is interacting with your profile|   
| :bird: | [Swift 5](https://developer.apple.com/swift/) |  
| :arrow_right: | [Go](https://golang.org/) |  

## Quick Start

### Swift 

```swift
# Install dependencies

pod install
```

### Go

```go
# Install dependencies

go get ./...
```

```golang
# Add MongoDB URL to config.go

func GetConfig() *Config {
	uri, exists := os.LookupEnv("DB_URI")
	if exists {
		return &Config{
			DbURI: uri,
			Port:  ":8080",
		}
	}
	return &Config{}
}

```

## Libraries Used

### Swift

* [NextLevel](https://github.com/NextLevel/NextLevel) - Rad Media Capture in Swift 
* [Pageboy](https://github.com/uias/Pageboy) - A simple, highly informative page view controller
* [RPCircularProgress](https://github.com/iwasrobbed/RPCircularProgress) - Circular progress UIView subclass with UIProgressView properties
* [SwiftKeychainWrapper](https://github.com/jrendel/SwiftKeychainWrapper) - A simple wrapper for the iOS Keychain to allow you to use it in a similar fashion to User Defaults
* [lottie-ios](https://github.com/airbnb/lottie-ios) - An iOS library to natively render After Effects vector animations
* [GoogleSignIn](https://developers.google.com/identity/sign-in/ios#swift) - Add Google Sign-In to Your iOS App
* [Pastel](https://github.com/cruisediary/Pastel) - Gradient animation effects

### Go

* [Google/UUID](https://github.com/google/uuid) - Go package for UUIDs based on RFC 4122 and DCE 1.1: Authentication and Security Services
* [mongo-go-driver](https://github.com/mongodb/mongo-go-driver) - The Go driver for MongoDB
* [bcrypt](https://godoc.org/golang.org/x/crypto/bcrypt) - Go package for the bcrypt hashing algorithm
* [aws-sdk-go](https://github.com/aws/aws-sdk-go) - AWS SDK for the Go programming language
* [govalidator](https://github.com/thedevsaddam/govalidator) - Request data validation
* [gorilla/mux](https://github.com/gorilla/mux) - A powerful HTTP router and URL matcher for building Go web servers

## License

windmill is available under the MIT license, see the [LICENSE](https://github.com/liamreardon/windmill/blob/master/LICENSE) file for more information.
