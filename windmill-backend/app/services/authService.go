package services

import (
	"golang.org/x/crypto/bcrypt"
)

func CheckHashedPassword(password string, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}


