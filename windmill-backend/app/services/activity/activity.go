package activities

import (
	"context"
	"github.com/liamreardon/windmill/windmill-backend/app/models"
	"github.com/liamreardon/windmill/windmill-backend/app/services/sorting"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

func GetUserActivity(collection *mongo.Collection, ctx context.Context, userId string) ([]models.Activity, error) {
	var user models.User
	res := collection.FindOne(ctx, bson.M{"userid": userId})
	if res.Err() != nil {
		return []models.Activity{}, res.Err()
	}
	res.Decode(&user)
	activities := user.Activity
	sorting.SortActivities(activities)
	return activities, nil
}