package handlers

import (
	"context"
	"github.com/google/uuid"
	"github.com/gorilla/mux"
	"github.com/liamreardon/windmill/windmill-backend/app/services/aws"
	"github.com/liamreardon/windmill/windmill-backend/app/services/following"
	"github.com/liamreardon/windmill/windmill-backend/app/services/upload"
	"github.com/liamreardon/windmill/windmill-backend/app/services/user"
	"go.mongodb.org/mongo-driver/mongo"
	"io"
	"net/http"
	"strconv"
	"time"
)

func UpdateDisplayPicture(client *mongo.Client, w http.ResponseWriter, r *http.Request) {
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

	path, err := aws.UpdateDisplayPicture(file, filename, userId)
	if err != nil {
		respondError(w, http.StatusInternalServerError, map[string]interface{}{
			"message":"error uploading file",
		})
		return
	}

	collection := client.Database("windmill-master").Collection("Users")
	ctx, _ := context.WithTimeout(context.Background(), 5*time.Second)
	res, err := upload.AssignUserDisplayPicturePath(collection, ctx, userId, path)
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
	caption := vars["caption"]
	file, _, err := r.FormFile("file")
	if err != nil {
		respondError(w, http.StatusInternalServerError, map[string]interface{}{
			"message":"error uploading file",
		})
		return
	}
	defer file.Close()

	videoId := uuid.New().String()

	url, err := aws.UploadVideoToS3(file, videoId, userId)
	if err != nil {
		respondError(w, http.StatusInternalServerError, map[string]interface{}{
			"message":"error uploading file",
		})
		return
	}

	collection := client.Database("windmill-master").Collection("Users")
	ctx, _ := context.WithTimeout(context.Background(), 5*time.Second)
	res, err := upload.AddVideoToUserPosts(collection, ctx, userId, videoId, url, caption)
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

func GetDisplayPicture(client *mongo.Client, w http.ResponseWriter, r *http.Request) {
	 vars := mux.Vars(r)
	 userId := vars["userId"]
	 collection := client.Database("windmill-master").Collection("Users")
	 ctx, _ := context.WithTimeout(context.Background(), 5*time.Second)

	 dp, err := user.GetDisplayPicture(collection, ctx, userId)

	 if err != nil {
		 respondError(w, http.StatusInternalServerError, map[string]interface{}{
			 "message":err,
		 })
		 return
	 }

	 fileHeader := make([]byte, 512)
	 dp.Read(fileHeader)
	 fileContentType := http.DetectContentType(fileHeader)
	 fileStat, _ := dp.Stat()
	 fileSize := strconv.FormatInt(fileStat.Size(), 10)

	 w.Header().Set("Content-Disposition", "attachment; filename="+dp.Name())
	 w.Header().Set("Content-Type", fileContentType)
	 w.Header().Set("Content-Length", fileSize)

	 dp.Seek(0, 0)
	 io.Copy(w, dp)
	 dp.Close()
	 return
}

func UserFollowingHandler(client *mongo.Client, w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	username := vars["username"]
	followingUsername := vars["followingUsername"]
	followingStatus, _ := strconv.ParseBool(vars["followingStatus"])

	collection := client.Database("windmill-master").Collection("Users")
	ctx, _ := context.WithTimeout(context.Background(), 5*time.Second)

	err := following.UserFollowingService(collection, ctx, username, followingUsername, followingStatus)

	if err != nil {
		respondError(w, http.StatusInternalServerError, map[string]interface{}{
			"message":err,
		})
		return
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"message":"successfully updated following user status",
	})
}

func GetUser(client *mongo.Client, w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	username := vars["username"]

	collection := client.Database("windmill-master").Collection("Users")
	ctx, _ := context.WithTimeout(context.Background(), 5*time.Second)

	usr, err := user.GetUser(collection, ctx, username)

	if err != nil {
		respondError(w, http.StatusInternalServerError, map[string]interface{}{
			"message":err,
		})
		return
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"message":"successfully retrieved user",
		"user":usr,
	})
}




