package handlers

import (
	"context"
	"fmt"
	"github.com/dgrijalva/jwt-go"
	"github.com/liamreardon/windmill/windmill-backend/app/services"
	"go.mongodb.org/mongo-driver/mongo"
	"net/http"
	"time"
)

type Claims struct {
	Username string `json:"username"`
	jwt.StandardClaims
}

var jwtKey = []byte("my_secret_key")

func Login(client *mongo.Client, w http.ResponseWriter, r *http.Request) {

	res, err := services.ValidateLoginRequest(r)
	if len(err) > 0 {
		respondError(w, http.StatusBadRequest, map[string]interface{}{
			"message":"Invalid request body",
			"error":err,
		})
		return
	}

	info, error := services.VerifyGoogleToken(res.TokenId)
	if error != nil {
		respondError(w, http.StatusBadRequest, map[string]interface{}{
			"message":"Token could not be verified",
			"error":error,
		})
		return
	}

	collection := client.Database("windmill-master").Collection("Users")
	ctx, _ := context.WithTimeout(context.Background(), 5*time.Second)

	user, e := services.GetUser(collection, ctx, res, info)

	// Send user to username creation page
	if len(e) > 0 {
		respondJSON(w, http.StatusCreated, map[string]interface{}{
			"message":e,
			"authFlag": "1",
		})
		return
	}

	// Login user - redirect to homepage
	services.GenerateToken(user, w)

	respondJSON(w, http.StatusCreated, map[string]interface{}{
		"message":"Login successful!",
		"authFlag": "2",
	})
}

func SignUp(client *mongo.Client, w http.ResponseWriter, r *http.Request) {
	//hash := "$2a$14$ajq8Q7fbtFRQvXpdCq7Jcuy.Rx1h/L4J60Otx.gyNLbAYctGMJ9tK"
	//ok := services.CheckHashedPassword("secret", hash)
	//if !ok {
	//	w.WriteHeader(http.StatusUnauthorized)
	//	return
	//}
	//w.Write([]byte(fmt.Sprintf("auth works", ok)))

	res, err := services.ValidateSignupRequest(r)
	if len(err) > 0 {
		respondError(w, http.StatusBadRequest, map[string]interface{}{
			"message":"Invalid request body",
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

	//_, result := services.SignUpUser(collection, ctx, res)
	respondJSON(w, http.StatusCreated, map[string]interface{}{
		"message":"username available",
		"available":true,
	})
}

func Welcome(client *mongo.Client, w http.ResponseWriter, r *http.Request) {
	c, err := r.Cookie("token")
	if err != nil {
		if err != nil {
			if err == http.ErrNoCookie {
				w.WriteHeader(http.StatusUnauthorized)
				return
			}
			w.WriteHeader(http.StatusBadRequest)
			return
		}
	}

	tknStr := c.Value
	claims := &Claims{}

	tkn, err := jwt.ParseWithClaims(tknStr, claims, func(token *jwt.Token) (interface{}, error) {
		return jwtKey, nil
	})
	if err != nil {
		if err == jwt.ErrSignatureInvalid {
			w.WriteHeader(http.StatusUnauthorized)
			return
		}
		w.WriteHeader(http.StatusBadRequest)
		return
	}
	if !tkn.Valid {
		w.WriteHeader(http.StatusUnauthorized)
		return
	}

	w.Write([]byte(fmt.Sprintf("Welcome %s!", claims.Username)))
}

