package post

import (
	"context"
	"errors"
	"github.com/google/uuid"
	"github.com/liamreardon/windmill/windmill-backend/app/models"
	"github.com/liamreardon/windmill/windmill-backend/app/services/sorting"
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

	var post models.Post
	for i := range user.Posts {
		if user.Posts[i].PostId == postId {
			post = user.Posts[i]
		}
	}

	if likedStatus {
		activity := models.Activity{
			Id:       uuid.New().String(),
			Type:     "LIKED",
			Username: user2.Username,
			Post: 	  post,
			Body:     user2.Username + " liked your post.",
			Date:     time.Now(),
		}
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

		if userId == postUserId {
			return nil
		}

		_, err = collection.UpdateOne(ctx, bson.M{"userid":postUserId, "posts.postid":postId}, bson.D{
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
					{"postid", postId},
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

func AddCommentToPost(collection *mongo.Collection, ctx context.Context, postUserId string, postId string, userId string, data string) error {
	var user models.User
	res := collection.FindOne(ctx, bson.M{"userid":userId})
	if res.Err() != nil {
		return res.Err()
	}
	res.Decode(&user)

	var user2 models.User
	res = collection.FindOne(ctx, bson.M{"userid":postUserId})
	if res.Err() != nil {
		return res.Err()
	}
	res.Decode(&user2)

	var post models.Post
	for i := range user2.Posts {
		if user2.Posts[i].PostId == postId {
			post = user2.Posts[i]
		}
	}

	var comment = models.Comment{
		CommentId:          uuid.New().String(),
		Username:           user.Username,
		Verified:            user.Verified,
		UserDisplayPicture: user.DisplayPicture,
		CommentData:        data,
		DateAdded:          time.Now(),
	}

	activity := models.Activity{
		Id:       uuid.New().String(),
		Type:     "COMMENT",
		Username: user.Username,
		Comment:  comment,
		Post:     post,
		Body:     user.Username + " commented on your post.",
		Date:     time.Now(),
	}

	_, err := collection.UpdateOne(ctx, bson.M{"userid":postUserId, "posts.postid":postId}, bson.D{
		{"$push", bson.D{
			{"posts.$.comments", comment},
		}},
	})

	if err != nil {
		return err
	}

	if userId == postUserId {
		return nil
	}

	_, err = collection.UpdateOne(ctx, bson.M{"userid":postUserId, "posts.postid":postId}, bson.D{
		{"$push", bson.D{
			{"activity", activity},
		}},
	})

	if err != nil {
		return err
	}

	return nil
}

func GetComments(collection *mongo.Collection, ctx context.Context, postUserId string, postId string) ([]models.Comment, error) {
	var user models.User
	res := collection.FindOne(ctx, bson.M{"userid":postUserId, "posts.postid":postId})
	if res.Err() != nil {
		return []models.Comment{}, res.Err()
	}
	res.Decode(&user)

	var post models.Post
	for i := range user.Posts {
		if user.Posts[i].PostId == postId {
			post = user.Posts[i]
		}
	}

	if post.PostId == "" {
		return []models.Comment{}, errors.New("Post doesn't exist")
	}

	comments := post.Comments
	sorting.SortComments(comments)

	return comments, nil
}