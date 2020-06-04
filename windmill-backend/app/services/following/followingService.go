package following

import (
	"context"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

func UserFollowingService(collection *mongo.Collection, ctx context.Context, username string, followingUsername string, followingStatus bool) error {

	if followingStatus {
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

		return nil
	}
}
