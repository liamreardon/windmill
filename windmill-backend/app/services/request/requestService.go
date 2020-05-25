package request

import (
	"github.com/liamreardon/windmill/windmill-backend/app/models"
	"github.com/thedevsaddam/govalidator"
	"net/http"
	"errors"
)

func ValidateLoginRequest(r *http.Request) (models.GoogleToken, error) {
	var token models.GoogleToken

	rules := govalidator.MapData{
		"tokenId": 	{"required"},
	}

	opts := govalidator.Options{
		Request: r,
		Data:    &token,
		Rules:   rules,
		RequiredDefault: true,
	}

	v := govalidator.New(opts)
	e := v.ValidateJSON()

	if len(e) > 0 {
		return token, errors.New("Invalid request body")
	}

	return token, nil
}

func ValidateSignupRequest(r *http.Request) (*models.User, error) {
	var user models.User

	rules := govalidator.MapData{
		"username": 	{"required"},
	}

	opts := govalidator.Options{
		Request: r,
		Data:    &user,
		Rules:   rules,
		RequiredDefault: true,
	}

	v := govalidator.New(opts)
	e := v.ValidateJSON()

	if len(e) > 0 {
		err := errors.New("Invalid request body")
		return &user, err
	}

	return &user, nil
}
