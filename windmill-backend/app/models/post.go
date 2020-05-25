package models

type Post struct {
	Id string `json:"id"`
	UserId string `json:"userid"`
	NumLikes int `json:"numlikes"`
	Likers []string `json:"likers"`
	Url string `json:"url"`
}
