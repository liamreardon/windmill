package search

import (
	"context"
	"errors"
	"github.com/liamreardon/windmill/windmill-backend/app/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

func GetUsersStartingWithSubstring(collection *mongo.Collection, ctx context.Context, substring string) ([]models.ProtectedUser, error) {
	users := []models.User{}
	cur, err := collection.Find(ctx, bson.D{{"username", primitive.Regex{"^"+substring, ""}}})
	if err != nil {
		return []models.ProtectedUser{}, errors.New("Couldn't get users matching that substring")
	}
	for cur.Next(ctx) {
		var user models.User
		cur.Decode(&user)
		users = append(users, user)
	}

	protectedUsers := []models.ProtectedUser{}
	for _, user := range users {
		usr := models.ProtectedUser{
			Username:       user.Username,
			DisplayName:    user.DisplayName,
			DisplayPicture: user.DisplayPicture,
			Verified:       	user.Verified,
			Relations:      user.Relations,
			Posts:          []models.Post{},
			NumPosts: len(user.Posts),
		}

		protectedUsers = append(protectedUsers, usr)
	}

	return protectedUsers, nil
}


