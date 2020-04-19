package models

// User struct
type User struct {
	Id string
	FirstName string
	LastName string
	Username string
	Email string
	Password string
	Relations Relationships
}

// Credentials struct
type Credentials struct {
	Username string `json:"username"`
	Password string `json:"password"`
}


