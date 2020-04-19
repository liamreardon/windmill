package handlers

import (
	"encoding/json"
	"net/http"
)

// Response in JSON format
func respondJSON(w http.ResponseWriter, status int, payload interface{}) {
	res, err := json.Marshal(payload)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(err.Error()))
		return
	}
	w.Header().Set("Content-Type", "application/json")
	enableCors(&w)
	w.WriteHeader(status)
	w.Write(res)
}

// Error response in JSON format
func respondError(w http.ResponseWriter, code int, msg interface{}) {
	respondJSON(w, code, msg)
}

// Enable CORS
func enableCors(w *http.ResponseWriter) {
	(*w).Header().Set("Access-Control-Allow-Origin", "*")
}
