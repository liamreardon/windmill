package handlers

import (
	"context"
	"fmt"
	"github.com/gorilla/mux"
	"github.com/liamreardon/windmill/windmill-backend/app/services/search"
	"go.mongodb.org/mongo-driver/mongo"
	"net/http"
	"strings"
	"time"
)

func SearchForUser(client *mongo.Client, w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	substring := strings.ToLower(vars["substring"])
	fmt.Println(substring)
	collection := client.Database("windmill-master").Collection("Users")
	ctx, _ := context.WithTimeout(context.Background(), 5*time.Second)
	users, err := search.GetUsersStartingWithSubstring(collection, ctx, substring)
	if err != nil {
		respondError(w, http.StatusInternalServerError, map[string]interface{}{
			"message":err,
		})
		return
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"users":users,
	})
}
