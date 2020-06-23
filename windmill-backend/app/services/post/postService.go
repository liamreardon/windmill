package post

import (
	"context"
	"github.com/google/uuid"
	"github.com/liamreardon/windmill/windmill-backend/app/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"time"
)

func PostLikedService(collection *mongo.Collection, ctx context.Context, postUserId string, userId string, postId string, likedStatus bool) error {
	var user models.User
	res := collection.FindOne(ctx, bson.M{"userid":postUserId})
	if res.Err() != nil {
		return res.Err()
	}
	res.Decode(&user)

	var user2 models.User
	res = collection.FindOne(ctx, bson.M{"userid":userId})
	if res.Err() != nil {
		return res.Err()
	}
	res.Decode(&user2)

	var postImage string
	for i := range user.Posts {
		if user.Posts[i].PostId == postId {
			postImage = user.Posts[i].Thumbnail
		}
	}

	if likedStatus {
		activity := models.Activity{
			Id:       uuid.New().String(),
			Type:     "LIKED",
			Username: user2.Username,
			PostId:   postId,
			Body:     user2.Username + " liked your post.",
			Image: 	  postImage,
			Date:     time.Now(),
		}
		_, err := collection.UpdateOne(ctx, bson.M{"userid":postUserId, "posts.postid":postId}, bson.D{
			{"$push", bson.D{
				{"posts.$.likers", userId},
			}},
			{"$inc", bson.D{
				{"posts.$.numlikes", 1},
			}},
			{"$push", bson.D{
				{"activity", activity},
			}},
		})

		if err != nil {
			return err
		}

		return nil

	} else {
		_, err := collection.UpdateOne(ctx, bson.M{"userid":postUserId, "posts.postid":postId}, bson.D{
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

		_, err = collection.UpdateOne(ctx, bson.M{"userid": postUserId, "activity.postid": postId}, bson.D{
			{"$pull", bson.D{
				{"activity", bson.D{
					{"username", user2.Username},
				}},
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