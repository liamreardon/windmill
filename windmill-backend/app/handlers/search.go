package handlers

import (
	"fmt"
	"github.com/gorilla/mux"
	"go.mongodb.org/mongo-driver/mongo"
	"net/http"
)

func SearchForUser(client *mongo.Client, w http.ResponseWriter, r *http.Request) {

	vars := mux.Vars(r)
	substring := vars["substring"]
	fmt.Println(substring)
}
