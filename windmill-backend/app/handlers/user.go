package handlers

import (
	"context"
	"github.com/gorilla/mux"
	"github.com/liamreardon/windmill/windmill-backend/app/services"
	"github.com/liamreardon/windmill/windmill-backend/app/services/aws"
	"go.mongodb.org/mongo-driver/mongo"
	"net/http"
	"time"
)

func UpdateDisplayPicture(client *mongo.Client, w http.ResponseWriter, r *http.Request) {

	vars := mux.Vars(r)
	userId := vars["userId"]

	file, header, err := r.FormFile("profile_img")
	if err != nil {
		respondError(w, http.StatusInternalServerError, map[string]interface{}{
			"message":"error uploading file",
		})
		return
	}
	defer file.Close()

	filename := header.Filename

	path, err := aws.UpdateDisplayPicture(file, filename, userId)
	if err != nil {
		respondError(w, http.StatusInternalServerError, map[string]interface{}{
			"message":"error uploading file",
		})
		return
	}

	collection := client.Database("windmill-master").Collection("Users")
	ctx, _ := context.WithTimeout(context.Background(), 5*time.Second)
	res, err := services.AssignUserDisplayPicturePath(collection, ctx, userId, path)
	if err != nil {
		respondError(w, http.StatusInternalServerError, map[string]interface{}{
			"message":err,
		})
		return
	}

	respondJSON(w, http.StatusCreated, map[string]interface{}{
		"message":res,
	})

}

func UploadVideo(client *mongo.Client, w http.ResponseWriter, r *http.Request) {

	vars := mux.Vars(r)
	userId := vars["userId"]
	file, header, err := r.FormFile("file")
	if err != nil {
		respondError(w, http.StatusInternalServerError, map[string]interface{}{
			"message":"error uploading file",
		})
		return
	}
	defer file.Close()

	filename := header.Filename

	aws.UploadVideoToS3(file, filename, userId)

}




