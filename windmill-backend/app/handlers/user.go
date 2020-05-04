package handlers

import (
	"github.com/gorilla/mux"
	"github.com/liamreardon/windmill/windmill-backend/app/services/aws"
	"go.mongodb.org/mongo-driver/mongo"
	"net/http"
)

func UpdateDisplayPicture(client *mongo.Client, w http.ResponseWriter, r *http.Request) {

	vars := mux.Vars(r)
	username := vars["userId"]

	file, header, err := r.FormFile("profile_img")
	if err != nil {
		respondError(w, http.StatusInternalServerError, map[string]interface{}{
			"message":"error uploading file",
		})
		return
	}
	defer file.Close()

	filename := header.Filename

	aws.UpdateDisplayPicture(file, filename, username)

}




