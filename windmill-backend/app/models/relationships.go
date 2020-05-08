package models

// Relationships struct
type Relationships struct {
	Followers []string `json:"followers"`
	Following []string `json:"following"`
	LikedPosts []string `json:"likedposts"`
}
