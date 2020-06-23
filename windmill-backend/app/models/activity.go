package models

import "time"

type Activity struct {
	Id string `json:"id"`
	Type string `json:"type"`
	Username string `json:"username"`
	PostId string `json:"postid"`
	Body string `json:"body"`
	Image string `json:"image"`
	Date time.Time `json:"date"`
}

