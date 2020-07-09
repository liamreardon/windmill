package models

import "time"

type Activity struct {
	Id string `json:"id"`
	Type string `json:"type"`
	Username string `json:"username"`
	UsernameF string `json:"usernamef"`
	PostId string `json:"postid"`
	Post Post `json:"post"`
	Comment Comment `json:"comment"`
	Body string `json:"body"`
	Image string `json:"image"`
	Date time.Time `json:"date"`
}

