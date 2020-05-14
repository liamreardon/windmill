package services

import (
	"context"
	"errors"
	"fmt"
	"github.com/liamreardon/windmill/windmill-backend/app/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

func AssignUserDisplayPicturePath(collection *mongo.Collection, ctx context.Context, userId string, path string) (string, error) {
	res, err := collection.UpdateOne(ctx, bson.M{"userid":userId}, bson.D{
		{"$set", bson.D{
			{"displaypicture", path},
		}},
	})

	if err != nil {
		return "", errors.New("error uploading display picture")
	}

	return fmt.Sprintf("successfully uploaded display picture, upserted %d", res.UpsertedCount), nil
}

func AddVideoToUserPosts(collection *mongo.Collection, ctx context.Context, userId string, videoId string, path string) (string, error) {
	post := models.Post{
		Id:	videoId,
		NumLikes: 0,
		Likers: nil,
		Path: path,
	}

	res, err := collection.UpdateOne(ctx, bson.M{"userid":userId}, bson.D{
		{"$push", bson.D{
			{"posts", post},
		}},
	})

	if err != nil {
		return "", errors.New("error uploading video")
	}

	return fmt.Sprintf("successfully uploaded video, upserted %d", res.UpsertedCount), nil
}
