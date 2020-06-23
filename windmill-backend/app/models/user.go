package models

import "time"

// User struct
type User struct {
	UserId string `json:"userId"`
	UserToken GoogleToken `json:"userToken"`
	DisplayName string `json:"displayName"`
	DisplayPicture string `json:"displayPicture"`
	Username string `json:"username"`
	Email string `json:"email"`
	Verified bool `json:"verified"`
	Relations Relationships `json:"relations"`
	Posts []Post `json:"posts"`
	Activity []Activity `json:"activity"`
	DateJoined time.Time `json:"dateJoined"`
}

type ProtectedUser struct {
	Username string `json:"username"`
	DisplayName string `json:"displayName"`
	DisplayPicture string `json:"displayPicture"`
	Verified bool `json:"verified"`
	Relations Relationships `json:"relations"`
	Posts []Post `json:"posts"`
	NumPosts int `json:"numPosts"`
	Activity []Activity `json:"activity"`
}

// Credentials struct
type Credentials struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

// Google Token Struct
type GoogleToken struct {
	TokenId string `json:"tokenId"`
}




