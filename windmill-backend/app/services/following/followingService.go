package following

import (
	"context"
	"github.com/google/uuid"
	"github.com/liamreardon/windmill/windmill-backend/app/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"time"
)

func UserFollowingService(collection *mongo.Collection, ctx context.Context, username string, followingUsername string, followingStatus bool) error {
	var user models.User
	res := collection.FindOne(ctx, bson.M{"username":followingUsername})
	if res.Err() != nil {
		return res.Err()
	}
	res.Decode(&user)

	var user2 models.User
	res = collection.FindOne(ctx, bson.M{"username":username})
	if res.Err() != nil {
		return res.Err()
	}
	res.Decode(&user2)

	if followingStatus {
		activity := models.Activity{
			Id:       uuid.New().String(),
			Type:     "FOLLOWED",
			Username: username,
			UsernameF: username,
			Body:     username + " followed you.",
			Image:    user2.DisplayPicture,
			Date:     time.Now(),
		}
		_, err := collection.UpdateOne(ctx, bson.M{"username":username}, bson.D{
			{"$push", bson.D{
				{"relations.following", followingUsername},
			}},
			{"$inc", bson.D{
				{"relations.numfollowing", 1},
			}},
		})

		if err != nil {
			return err
		}

		_, err = collection.UpdateOne(ctx, bson.M{"username":followingUsername}, bson.D{
			{"$push", bson.D{
				{"relations.followers", username},
			}},
			{"$inc", bson.D{
				{"relations.numfollowers", 1},
			}},
		})

		if err != nil {
			return err
		}

		_, err = collection.UpdateOne(ctx, bson.M{"username":followingUsername}, bson.D{
			{"$push", bson.D{
				{"activity", activity},
			}},
		})

		if err != nil {
			return err
		}

		return nil

	} else {
		_, err := collection.UpdateOne(ctx, bson.M{"username":username}, bson.D{
			{"$pull", bson.D{
				{"relations.following", followingUsername},
			}},
			{"$inc", bson.D{
				{"relations.numfollowing", -1},
			}},
		})

		if err != nil {
			return err
		}

		_, err = collection.UpdateOne(ctx, bson.M{"username":followingUsername}, bson.D{
			{"$pull", bson.D{
				{"relations.followers", username},
			}},
			{"$inc", bson.D{
				{"relations.numfollowers", -1},
			}},
		})

		if err != nil {
			return err
		}

		var usernameActivity string
		for i := range user.Activity {
			if user.Activity[i].Username == username {
				usernameActivity = user.Activity[i].Username
				break
			}
		}

		_, err = collection.UpdateOne(ctx, bson.M{"username":followingUsername}, bson.D{
			{"$pull", bson.D{
				{"activity", bson.D{
					{"usernamef", usernameActivity},
				}},
			}},
		})

		if err != nil {
			return err
		}

		return nil
	}
}
