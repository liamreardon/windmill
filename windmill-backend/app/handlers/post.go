package handlers

import (
	"context"
	"encoding/json"
	"github.com/gorilla/mux"
	"github.com/liamreardon/windmill/windmill-backend/app/services/post"
	"go.mongodb.org/mongo-driver/mongo"
	"io/ioutil"
	"net/http"
	"strconv"
	"time"
)

func PostLiked(client *mongo.Client, w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	postUserId := vars["postUserId"]
	userId := vars["userId"]
	postId := vars["postId"]
	likedStatus, _ := strconv.ParseBool(vars["likedStatus"])

	collection := client.Database("windmill-master").Collection("Users")
	ctx, _ := context.WithTimeout(context.Background(), 5*time.Second)

	err := post.PostLikedService(collection, ctx, postUserId, userId, postId, likedStatus)

	if err != nil {
		respondError(w, http.StatusInternalServerError, map[string]interface{}{
			"error":err,
		})
		return
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"message":"successfully updated users liked status on post",
	})
}

func DeletePost(client *mongo.Client, w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userId := vars["userId"]
	postId := vars["postId"]

	collection := client.Database("windmill-master").Collection("Users")
	ctx, _ := context.WithTimeout(context.Background(), 5*time.Second)

	err := post.DeletePost(collection, ctx, userId, postId)

	if err != nil {
		respondError(w, http.StatusInternalServerError, map[string]interface{}{
			"error":err,
		})
		return
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"message":"successfully updated users liked status on post",
	})
}

func PostCommentedOn(client *mongo.Client, w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	postUserId := vars["postUserId"]
	postId := vars["postId"]
	userId := vars["userId"]

	res, err := ioutil.ReadAll(r.Body)

	if err != nil {
		respondError(w, http.StatusInternalServerError, map[string]interface{}{
			"message":"error uploading file",
		})
		return
	}

	var dat map[string]string

	if err := json.Unmarshal(res, &dat); err != nil {
		panic(err)
	}

	collection := client.Database("windmill-master").Collection("Users")
	ctx, _ := context.WithTimeout(context.Background(), 5*time.Second)

	err = post.AddCommentToPost(collection, ctx, postUserId, postId, userId, dat["comment"])
	if err != nil {
		respondError(w, http.StatusInternalServerError, map[string]interface{}{
			"error":err,
		})
		return
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"message":"successfully added comment to post",
	})
}

func GetPostComments(client *mongo.Client, w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	postUserId := vars["postUserId"]
	postId := vars["postId"]

	collection := client.Database("windmill-master").Collection("Users")
	ctx, _ := context.WithTimeout(context.Background(), 5*time.Second)

	comments, err := post.GetComments(collection, ctx, postUserId, postId)

	if err != nil {
		respondError(w, http.StatusInternalServerError, map[string]interface{}{
			"error":err,
		})
		return
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"comments":comments,
	})
}

