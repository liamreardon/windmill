package upload

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

func AddVideoToUserPosts(collection *mongo.Collection, ctx context.Context, userId string, videoId string, url string) (string, error) {
	user := models.User{}

	collection.FindOne(ctx, bson.M{"userid":userId}).Decode(&user)

	if len(user.Username) == 0 {
		return "", errors.New("Couldn't retrieve user from database")
	}

	post := models.Post{
		PostId:	videoId,
		UserId: user.UserId,
		Verified: user.Verified,
		Username: user.Username,
		Caption: "",
		Comments: []models.Comment{},
		NumLikes: 0,
		Likers: []string{},
		Url: url,
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
