package feed

import (
	"context"
	"errors"
	"fmt"
	"github.com/liamreardon/windmill/windmill-backend/app/models"
	"github.com/liamreardon/windmill/windmill-backend/app/services/sorting"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

func GetUserFeed(collection *mongo.Collection, ctx context.Context, username string) ([]models.Post, error) {
	var user models.User
	collection.FindOne(ctx, bson.M{"username":username}).Decode(&user)
	if user.Username == "" {
		return nil, errors.New("could't get user feed")
	}
	posts := user.Posts
	sorting.SortPosts(posts)
	return posts, nil
}

func GetFeed(collection *mongo.Collection, ctx context.Context, username string) ([]models.Post, error) {
	var user models.User
	collection.FindOne(ctx, bson.M{"username":username}).Decode(&user)
	if user.Username == "" {
		return nil, errors.New("could't get user feed")
	}

	posts := []models.Post{}

	for i := range user.Posts {
		posts = append(posts, user.Posts[i])
	}

	for i := range user.Relations.Following {
		usrname := user.Relations.Following[i]
		fmt.Println(usrname)
		var usr models.User
		collection.FindOne(ctx, bson.M{"username":usrname}).Decode(&usr)
		if usr.Username == "" {
			continue
		}
		for i := range usr.Posts {
			posts = append(posts, usr.Posts[i])
		}
	}

	sorting.SortPosts(posts)
	return posts, nil
}
