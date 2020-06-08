package user

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
		return nil, errors.New("couldn't get image")
	}

	res.Decode(&user)
	dpPath := user.DisplayPicture
	dp, err := aws.GetUserDisplayPicture(dpPath)
	if err != nil {
		return nil, errors.New(err.Error())
	}
	return dp, nil
}

func GetUser(collection *mongo.Collection, ctx context.Context, username string) (models.ProtectedUser, error) {
	var user = models.User{}
	collection.FindOne(ctx, bson.M{"username":username}).Decode(&user)
	if len(user.Username) == 0 {
		return models.ProtectedUser{}, errors.New("couldn't get user")
	}

	usr := models.ProtectedUser{
		Username:       user.Username,
		DisplayName:    user.DisplayName,
		DisplayPicture: user.DisplayPicture,
		Verified:        user.Verified,
		Relations:      user.Relations,
		Posts:          user.Posts,
	}
	return usr, nil
}
