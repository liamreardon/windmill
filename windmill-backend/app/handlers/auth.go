package handlers

import (
	"context"
	"github.com/liamreardon/windmill/windmill-backend/app/services"
	"go.mongodb.org/mongo-driver/mongo"
	"net/http"
	"time"
)

func Login(client *mongo.Client, w http.ResponseWriter, r *http.Request) {

	res, err := services.ValidateLoginRequest(r)
	if err != nil {
		respondError(w, http.StatusBadRequest, map[string]interface{}{
			"error":err,
		})
		return
	}

	info, err := services.VerifyGoogleToken(res.TokenId)
	if err != nil {
		respondError(w, http.StatusBadRequest, map[string]interface{}{
			"message":"Token could not be verified",
			"error":err,
		})
		return
	}

	collection := client.Database("windmill-master").Collection("Users")
	ctx, _ := context.WithTimeout(context.Background(), 5*time.Second)

	user, e := services.GetUser(collection, ctx, res, info)

	// Send user to username creation page
	if len(e) > 0 {
		respondJSON(w, http.StatusOK, map[string]interface{}{
			"message":e,
			"tokenId":user.UserToken.TokenId,
			"authFlag": "1",
		})
		return
	}

	respondJSON(w, http.StatusOK ,map[string]interface{}{
		"message":"Login successful!",
		"authFlag": "2",
		"username": user.Username,
		"userId": user.UserId,
	})
}

func SignUp(client *mongo.Client, w http.ResponseWriter, r *http.Request) {

	res, err := services.ValidateSignupRequest(r)
	if err != nil {
		respondError(w, http.StatusBadRequest, map[string]interface{}{
			"error":err,
		})
		return
	}

	collection := client.Database("windmill-master").Collection("Users")
	ctx, _ := context.WithTimeout(context.Background(), 5*time.Second)

	userExists, message := services.CheckUserExists(collection, ctx, res.Username)
	if userExists {
		respondError(w, http.StatusConflict, map[string]interface{}{
			"message":message["result"],
			"available":false,
		})
		return
	}

	result, _, userId := services.SignUpUser(collection, ctx, res)
	if !result {
		respondError(w, http.StatusInternalServerError, map[string]interface{}{
			"message":"error connecting to database",
			"available":false,
		})
		return
	}

	respondJSON(w, http.StatusCreated, map[string]interface{}{
		"message":"username available",
		"available":true,
		"userId":userId,
	})
}


