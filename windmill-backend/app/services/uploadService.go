package services

import (
	"context"
	"errors"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

func AssignUserDisplayPicturePath(collection *mongo.Collection, ctx context.Context, userId string, path string) (string, error){

	res, err := collection.UpdateOne(ctx, bson.M{"userId":userId}, bson.D{
		{"$set", bson.D{
			{"displayPicture", path},
		}},
	})

	if err != nil {
		return "", errors.New("error uploading display picture")
	}

	print(res)

	return "successfully uploaded display picture", nil
}
