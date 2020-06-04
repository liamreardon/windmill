package models

// Relationships struct
type Relationships struct {
	Followers []string `json:"followers"`
	Following []string `json:"following"`
	NumFollowers int `json:"numfollowers"`
	NumFollowing int `json:"numfollowing"`
	LikedPosts []string `json:"likedposts"`
}
