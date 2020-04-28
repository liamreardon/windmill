package services

import (
	"github.com/liamreardon/windmill/windmill-backend/app/models"
	"github.com/thedevsaddam/govalidator"
	"net/http"
)

func ValidateLoginRequest(r *http.Request) (models.GoogleToken, map[string]interface{}) {
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
		err := map[string]interface{}{"validationError": e}
		return token, err
	}

	return token, map[string]interface{}{}
}

func ValidateSignupRequest(r *http.Request) (*models.User, map[string]interface{}) {
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
		err := map[string]interface{}{"validationError": e}
		return &user, err
	}

	return &user, map[string]interface{}{}
}
