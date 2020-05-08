package models

type Post struct {
	Id string `json:"id"`
	NumLikes int `json:"numlikes"`
	Likers []string `json:"likers"`
}
