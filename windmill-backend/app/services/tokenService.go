package services


import (
	"github.com/dgrijalva/jwt-go"
	"github.com/liamreardon/windmill/windmill-backend/app/models"
	"net/http"
	"time"
)

// Create the JWT key used to create the signature
var jwtKey = []byte("my_secret_key")

type Claims struct {
	Username string `json:"username"`
	jwt.StandardClaims
}

func GenerateToken(user models.User, w http.ResponseWriter) {

	expirationTime := time.Now().Add(5 * time.Minute)
	claims := &Claims{
		Username:       user.Username,
		StandardClaims: jwt.StandardClaims{
			ExpiresAt: expirationTime.Unix(),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, error := token.SignedString(jwtKey)
	if error != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	http.SetCookie(w, &http.Cookie{
		Name:       "token",
		Value:      tokenString,
		Expires:    expirationTime,
	})
}

