package services


import (
	"github.com/dgrijalva/jwt-go"
	"github.com/liamreardon/windmill/windmill-backend/app/models"
	"google.golang.org/api/oauth2/v2"
	"net/http"
	"time"
)

var httpClient = &http.Client{}

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

func VerifyGoogleToken(idToken string) (*oauth2.Tokeninfo, error) {
	oauth2Service, err := oauth2.New(httpClient)
	tokenInfoCall := oauth2Service.Tokeninfo()
	tokenInfoCall.IdToken(idToken)
	tokenInfo, err := tokenInfoCall.Do()
	if err != nil {
		return nil, err
	}
	return tokenInfo, nil
}