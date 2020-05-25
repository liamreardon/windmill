package models

type Post struct {
	PostId string `json:"postid"`
	UserId string `json:"userid"`
	NumLikes int `json:"numlikes"`
	Likers []string `json:"likers"`
	Url string `json:"url"`
}
