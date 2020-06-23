package sorting

import (
	"github.com/liamreardon/windmill/windmill-backend/app/models"
	"sort"
)

func SortPosts(posts []models.Post) {
	sort.Slice(posts, func(i, j int) bool {
		return posts[j].DateAdded.Before(posts[i].DateAdded)
	})
}

func SortActivities(activities []models.Activity) {
	sort.Slice(activities, func(i, j int) bool {
		return activities[j].Date.Before(activities[i].Date)
	})
}