package services

import (
	"context"
	"fmt"
	"github.com/google/uuid"
	"github.com/liamreardon/windmill/windmill-backend/app/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"golang.org/x/crypto/bcrypt"

	//"github.com/google/uuid"
	//"net/http"
)


func CheckHashedPassword(password string, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

func CheckUserExists(collection *mongo.Collection, ctx context.Context, email string, username string) (bool, map[string]interface{}) {

	 err := collection.FindOne(ctx, bson.M{"email":email})
	 fmt.Println("%T", err)
	 if err.Err() == nil {
	 	return true, map[string]interface{}{
			"message":"email has been taken",
			"error":err,
		}
	 }

	err = collection.FindOne(ctx, bson.M{"username":username})
	if err.Err() == nil {
		return true, map[string]interface{}{
			"message":"username has been taken",
			"error":err,
		}
	}

	return false, map[string]interface{}{
		"message":"credentials available!",
	}
}

func SignUpUser(collection *mongo.Collection, ctx context.Context, data *models.User) (bool, *mongo.InsertOneResult) {
	user := models.User{
		UserId:    uuid.New(),
		FirstName: data.FirstName,
		LastName:  data.LastName,
		Username:  data.Username,
		Email:     data.Email,
		Password:  data.Password,
		Relations: models.Relationships{},
	}
	res, _ := collection.InsertOne(ctx, user)
	return true, res
}


func GetUser(collection *mongo.Collection, ctx context.Context, creds *models.Credentials) (models.User, string){
	var user models.User
	collection.FindOne(ctx, bson.M{"username":creds.Username, "password":creds.Password}).Decode(&user)
	if len(user.Username) == 0 {
		return models.User{}, "That username and / or password don't match"
	}
	return user, ""
}




