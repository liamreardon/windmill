package feed

import (
	"context"
	"errors"
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
