package handlers

import (
	"context"
	"github.com/liamreardon/windmill/windmill-backend/app/services/auth"
	"github.com/liamreardon/windmill/windmill-backend/app/services/request"
	"github.com/liamreardon/windmill/windmill-backend/app/services/token"
	"go.mongodb.org/mongo-driver/mongo"
	"net/http"
	"time"
)

func Login(client *mongo.Client, w http.ResponseWriter, r *http.Request) {
	res, err := request.ValidateLoginRequest(r)
	if err != nil {
		respondError(w, http.StatusBadRequest, map[string]interface{}{
			"error":err,
		})
		return
	}

	info, err := token.VerifyGoogleToken(res.TokenId)
	if err != nil {
		respondError(w, http.StatusBadRequest, map[string]interface{}{
			"message":"Token could not be verified",
			"error":err,
		})
		return
	}

	collection := client.Database("windmill-master").Collection("Users")
	ctx, _ := context.WithTimeout(context.Background(), 5*time.Second)

	user, e := auth.GetUser(collection, ctx, res, info)

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
		"followers": user.Relations.Followers,
		"following": user.Relations.Following,
		"numFollowers": user.Relations.NumFollowers,
		"numFollowing": user.Relations.NumFollowing,
	})
}

func SignUp(client *mongo.Client, w http.ResponseWriter, r *http.Request) {
	res, err := request.ValidateSignupRequest(r)
	if err != nil {
		respondError(w, http.StatusBadRequest, map[string]interface{}{
			"error":err,
		})
		return
	}

	collection := client.Database("windmill-master").Collection("Users")
	ctx, _ := context.WithTimeout(context.Background(), 5*time.Second)

	userExists, message := auth.CheckUserExists(collection, ctx, res.Username)
	if userExists {
		respondError(w, http.StatusConflict, map[string]interface{}{
			"message":message["result"],
			"available":false,
		})
		return
	}

	result, _, user, userId := auth.SignUpUser(collection, ctx, res)
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
		"username": user.Username,
		"followers": user.Relations.Followers,
		"following": user.Relations.Following,
		"numFollowers": user.Relations.NumFollowers,
		"numFollowing": user.Relations.NumFollowing,
	})
}


