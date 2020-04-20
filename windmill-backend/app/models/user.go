package models

import (
	"github.com/google/uuid"
)

// User struct
type User struct {
	UserId uuid.UUID `json:"userId"`
	FirstName string `json:"firstName"`
	LastName string `json:"lastName"`
	Username string `json:"username"`
	Email string `json:"email"`
	Password string `json:"password"`
	Relations Relationships `json:"relations"`
}

// Credentials struct
type Credentials struct {
	Username string `json:"username"`
	Password string `json:"password"`
}


