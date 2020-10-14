<p><img src="https://github.com/liamreardon/windmill/blob/master/windmill_banner.png" style="max-width:100%;" alt="windmill"></p>

`windmill` is a simplified video-sharing social network built using [Swift 5](https://developer.apple.com/swift/) and [Go](https://golang.org/), where users can record, edit and post looping short-form videos.

|  | Features |
|:---------:|:---------------------------------------------------------------|
| :video_camera: | Record "TikTok" style looping videos |  
| :pencil2: | Add custom text and captions to your videos |
| :bust_in_silhouette: | Create an account and customize your profile |
| :green_heart: | Follow friends and like their videos |
| :newspaper: | Browse newsfeed of videos from users you follow |
| :wave: | View activity feed to see who is interacting with your profile |   
| :bird: | [Swift 5](https://developer.apple.com/swift/) |  
| :arrow_right: | [Go](https://golang.org/) |  

# Quick Start

## Data Stores

### - MongoDB - 

First you will need to create a MongoDB instance, this can be either local or via MongoDB Atlas. Note your database URL. 

### - AWS S3 -
Once this is done, you will need to create an AWS S3 bucket and set the store to public. Follow this link for instructions on how to make this public (https://docs.aws.amazon.com/AmazonS3/latest/user-guide/block-public-access-bucket.html).

## Swift

```swift
# Update and install deps

pod update
pod install
```


### Obtain Google Client ID and URL Scheme for GoogleSignIn

Navigate [here](https://developers.google.com/identity/sign-in/ios/start-integrating) to get both of those (https://developers.google.com/identity/sign-in/ios/start-integrating) and follow all instructions

```
# Add credentials and other config settings to Config.plist file

ROOT_URL = http://localhost:8080
BUCKET_URL = https://my-project.s3.us-east-2.amazonaws.com
GOOGLE_CLIENT_ID = ENTER ID HERE
APP_BUNDLE_ID = io.liamreardon.windmill.dev
APP_NAME = windmill
```

## Go

```go
# Build go.mod

go build
```

```go
# Install dependencies

go install
```

```
# Create .env file in windmill-backend directory and add MongoDB URI + AWS S3 vars

touch .env

# Include these lines but swap in your own urls and vars

DB_URI=mongodb://localhost:27017/myproject (this could be the uri for a local instance or MongoDB Atlas)

AWS_S3_BASE=https://myproject.s3.us-east-2.amazonaws.com/users/

AWS_S3_REGION=us-east-2

AWS_S3_BUCKET=my-project

```

```go
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

```go
# Run

go run main.go
```

## Project

- Have an idea for a feature? Open an [issue](https://github.com/liamreardon/windmill/issues).
- Found a bug? Open an [issue](https://github.com/liamreardon/windmill/issues).
- If you want to contribute to the project, submit a pull request.

## Libraries Used

### Swift

* [NextLevel](https://github.com/NextLevel/NextLevel) - Rad Media Capture in Swift
* [Pageboy](https://github.com/uias/Pageboy) - A simple, highly informative page view controller
* [RPCircularProgress](https://github.com/iwasrobbed/RPCircularProgress) - Circular progress UIView subclass with UIProgressView properties
* [SwiftKeychainWrapper](https://github.com/jrendel/SwiftKeychainWrapper) - A simple wrapper for the iOS Keychain to allow you to use it in a similar fashion to User Defaults
* [lottie-ios](https://github.com/airbnb/lottie-ios) - An iOS library to natively render After Effects vector animations
* [GoogleSignIn](https://developers.google.com/identity/sign-in/ios#swift) - Add Google Sign-In to Your iOS App
* [Pastel](https://github.com/cruisediary/Pastel) - Gradient animation effects
* [SDWebImage](https://github.com/SDWebImage/SDWebImage) - Asynchronous image downloader with cache support as a UIImageView category

### Go

* [Google/UUID](https://github.com/google/uuid) - Go package for UUIDs based on RFC 4122 and DCE 1.1: Authentication and Security Services
* [mongo-go-driver](https://github.com/mongodb/mongo-go-driver) - The Go driver for MongoDB
* [bcrypt](https://godoc.org/golang.org/x/crypto/bcrypt) - Go package for the bcrypt hashing algorithm
* [aws-sdk-go](https://github.com/aws/aws-sdk-go) - AWS SDK for the Go programming language
* [govalidator](https://github.com/thedevsaddam/govalidator) - Request data validation
* [gorilla/mux](https://github.com/gorilla/mux) - A powerful HTTP router and URL matcher for building Go web servers

## License

windmill is available under the MIT license, see the [LICENSE](https://github.com/liamreardon/windmill/blob/master/LICENSE) file for more information.
