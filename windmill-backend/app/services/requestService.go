package services

import (
	"github.com/liamreardon/windmill/windmill-backend/app/models"
	"github.com/thedevsaddam/govalidator"
	"net/http"
)

func ValidateAuthRequest(r *http.Request) (*models.Credentials, map[string]interface{}) {
	var creds models.Credentials

	rules := govalidator.MapData{
		"username": 	[]string{"required"},
		"password":		[]string{"required"},
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


