package services

import (
	"github.com/liamreardon/windmill/windmill-backend/app/models"
	"github.com/thedevsaddam/govalidator"
	"net/http"
)

func ValidateLoginRequest(r *http.Request) (*models.Credentials, map[string]interface{}) {
	var creds models.Credentials

	rules := govalidator.MapData{
		"username": 	{"required"},
		"password":		{"required"},
	}

	opts := govalidator.Options{
		Request: r,
		Data:    &creds,
		Rules:   rules,
		RequiredDefault: true,
	}

	v := govalidator.New(opts)
	e := v.ValidateJSON()

	if len(e) > 0 {
		err := map[string]interface{}{"validationError": e}
		return &creds, err
	}

	return &creds, map[string]interface{}{}
}

func ValidateSignupRequest(r *http.Request) (*models.User, map[string]interface{}) {
	var user models.User

	rules := govalidator.MapData{
		"firstName":     {"required"},
		"lastName": 	{"required"},
		"email":		{"required"},
		"username": 	{"required"},
		"password":		{"required"},
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
