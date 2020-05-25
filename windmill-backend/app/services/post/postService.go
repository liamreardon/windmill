package post

import (
	"fmt"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"context"
)

func PostLikedService(collection *mongo.Collection, ctx context.Context, userId string, postId string, likedStatus bool) {

	if likedStatus == true {
		res, err := collection.UpdateOne(ctx, bson.M{"userid":userId, "posts.postid":postId}, bson.D{
			{"$push", bson.D{
				{"posts.$.likers", userId},
			}},
			{"$inc", bson.D{
				{"posts.$.numlikes", 1},
			}},
		})

		fmt.Println(res)
		fmt.Println(err)
	} else {
		res, err := collection.UpdateOne(ctx, bson.M{"userid":userId, "posts.postid":postId}, bson.D{
			{"$pull", bson.D{
				{"posts.$.likers", userId},
			}},
			{"$inc", bson.D{
				{"posts.$.numlikes", -1},
			}},
		})

		fmt.Println(res)
		fmt.Println(err)
	}



}