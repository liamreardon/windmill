package services

import (
	"context"
	"errors"
	"github.com/liamreardon/windmill/windmill-backend/app/models"
	"github.com/liamreardon/windmill/windmill-backend/app/services/aws"
	"go.mongodb.org/mongo-driver/bson"
	"os"

	//"mime/multipart"
	//"errors"
	"go.mongodb.org/mongo-driver/mongo"
)


func GetDisplayPicture(collection *mongo.Collection, ctx context.Context, userId string) (*os.File, error) {
	var user = models.User{}
	res := collection.FindOne(ctx, bson.M{"userid": userId})

	if res.Err() != nil {

	}
	res.Decode(&user)
	dpPath := user.DisplayPicture
	dp, err := aws.GetUserDisplayPicture(dpPath)
	if err != nil {
		return nil, errors.New(err.Error())
	}
	return dp, nil

}
