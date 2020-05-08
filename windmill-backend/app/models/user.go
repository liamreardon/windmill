package models

import (
	"github.com/google/uuid"
)

// User struct
type User struct {
	UserId uuid.UUID `json:"userId"`
	UserToken GoogleToken `json:"userToken"`
	DisplayName string `json:"firstName"`
	DisplayPicture string `json:"displayPicture"`
	Username string `json:"username"`
	Email string `json:"email"`
	Verified bool `json:"verified"`
	Relations Relationships `json:"relations"`
	Posts []Post `json:"posts"`
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




