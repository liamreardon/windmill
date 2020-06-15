package post

import (
	"context"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

func PostLikedService(collection *mongo.Collection, ctx context.Context, postUserId string, userId string, postId string, likedStatus bool) error {
	if likedStatus {
		_, err := collection.UpdateOne(ctx, bson.M{"userid":postUserId, "posts.postid":postId}, bson.D{
			{"$push", bson.D{
				{"posts.$.likers", userId},
			}},
			{"$inc", bson.D{
				{"posts.$.numlikes", 1},
			}},
		})

		if err != nil {
			return err
		}

		return nil

	} else {
		_, err := collection.UpdateOne(ctx, bson.M{"userid":userId, "posts.postid":postId}, bson.D{
			{"$pull", bson.D{
				{"posts.$.likers", userId},
			}},
			{"$inc", bson.D{
				{"posts.$.numlikes", -1},
			}},
		})

		if err != nil {
			return err
		}

		return nil
	}
}

func DeletePost(collection *mongo.Collection, ctx context.Context, userId string, postId string) error {
	_, err := collection.DeleteOne(ctx, bson.M{"userid":userId, "posts.postid":postId})
	if err != nil {
		return err
	}
	return nil
}