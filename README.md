# :cyclone: windmill

`windmill` is a simplified video-sharing social network built using [Swift](https://developer.apple.com/swift/) and [Go](https://golang.org/), where users can record, edit and post looping short-form videos.

|  | Features |
|:---------:|:---------------------------------------------------------------|
| :video_camera: | Record "TikTok" style looping videos |  
| :pencil2: | Add custom text and captions to your videos |
| :bust_in_silhouette: | Create an account and customize your profile |
| :green_heart: | Follow friends and like their videos | 
| :newspaper: | Browse newsfeed of videos from users you follow |  
| :bird: | [Swift](https://developer.apple.com/swift/) |  
| :arrow_right: | [Go](https://golang.org/) |  

## Quick Start

### Swift 

```ruby
# Install dependencies
pod install
```

### Go

```ruby
# Install dependencies

go get ./...
```

```ruby
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



