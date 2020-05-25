package handlers

import (
	"context"
	"github.com/gorilla/mux"
	"github.com/liamreardon/windmill/windmill-backend/app/services/feed"
	"go.mongodb.org/mongo-driver/mongo"
	"net/http"
	"time"
)

func GetUserFeed(client *mongo.Client, w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userId := vars["userId"]
	collection := client.Database("windmill-master").Collection("Users")
	ctx, _ := context.WithTimeout(context.Background(), 5*time.Second)
	posts, err := feed.GetUserFeed(collection, ctx, userId)
	if err != nil {
		respondError(w, http.StatusInternalServerError, map[string]interface{}{
			"message":err,
		})
		return
	}

	respondJSON(w, http.StatusCreated, map[string]interface{}{
		"message":"successfully fetched posts",
		"posts": posts,
	})

}

func GetUserFollowingFeed(client *mongo.Client, w http.ResponseWriter, r *http.Request) {

}



