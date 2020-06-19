package config

import (
	"os"
)

type Config struct {
	DbURI string
	Port string
}

type AWS struct {
	Base string
	Region string
	Bucket string
}

// Returns config environment variables
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



