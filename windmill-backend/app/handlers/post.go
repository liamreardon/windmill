package handlers

import (
	"context"
	"github.com/gorilla/mux"
	"github.com/liamreardon/windmill/windmill-backend/app/services/post"
	"go.mongodb.org/mongo-driver/mongo"
	"net/http"
	"strconv"
	"time"
)

func PostLikedHandler(client *mongo.Client, w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userId := vars["userId"]
	postId := vars["postId"]
	likedStatus, _ := strconv.ParseBool(vars["likedStatus"])

	collection := client.Database("windmill-master").Collection("Users")
	ctx, _ := context.WithTimeout(context.Background(), 5*time.Second)

	post.PostLikedService(collection, ctx, userId, postId, likedStatus)
}