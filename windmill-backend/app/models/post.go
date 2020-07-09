package models

import "time"

type Post struct {
	PostId string `json:"postid"`
	UserId string `json:"userid"`
	Verified bool `json:"verified"`
	Username string `json:"username"`
	Caption string `json:"caption"`
	Comments []Comment `json:"comments"`
	NumLikes int `json:"numlikes"`
	Likers []string `json:"likers"`
	Url string `json:"url"`
	Thumbnail string `json:"thumbnail"`
	DateAdded time.Time `json:"dateAdded"`
}

type Comment struct {
	CommentId string `json:"commentid"`
	Username string `json:"username"`
	Verified bool `json:"verified"`
	UserDisplayPicture string `json:"userdisplay"`
	CommentData string `json:"commentdata"`
	DateAdded time.Time `json:"dateAdded"`
}
