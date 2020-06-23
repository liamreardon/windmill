package handlers

import (
	"context"
	"github.com/gorilla/mux"
	activities "github.com/liamreardon/windmill/windmill-backend/app/services/activity"
	"go.mongodb.org/mongo-driver/mongo"
	"net/http"
	"time"
)

func GetActivity(client *mongo.Client, w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userId := vars["userId"]
	collection := client.Database("windmill-master").Collection("Users")
	ctx, _ := context.WithTimeout(context.Background(), 5*time.Second)

	activity, err := activities.GetUserActivity(collection, ctx, userId)
	if err != nil {
		respondError(w, http.StatusInternalServerError, map[string]interface{}{
			"error":err,
		})
		return
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"message":"retrieved user activity",
		"activity":activity,
	})

}
