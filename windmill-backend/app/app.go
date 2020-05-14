package app

import (
	"context"
	"fmt"
	"github.com/gorilla/mux"
	"github.com/liamreardon/windmill/windmill-backend/app/handlers"
	"github.com/liamreardon/windmill/windmill-backend/config"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"log"
	"net/http"
	"time"
)

// Type App has a router and DB
type App struct {
	Router *mux.Router
	DB *mongo.Client
}

func (app *App) Init() {
	// Initialize context
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Load database URI environment variable
	config := config.GetConfig()

	if config.DbURI == "" {
		log.Fatal("Database URI does not exist.")
	}

	app.DB, _ = mongo.Connect(ctx, options.Client().ApplyURI(
		config.DbURI,
	))

	err := app.DB.Ping(context.TODO(), nil)

	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Connected to MongoDB!")

	app.Router = mux.NewRouter()
	app.setupRoutes()
	app.Run(config.Port)
}

// Sets up routes
func (app *App) setupRoutes() {

	// Auth routes
	app.Post("/api/auth/login", app.handleRequest(handlers.Login))
	app.Post("/api/auth/signup", app.handleRequest(handlers.SignUp))

	// User Routes
	app.Put("/api/user/{userId}/dp", app.handleRequest(handlers.UpdateDisplayPicture))
	app.Post("/api/user/{userId}/posts", app.handleRequest(handlers.UploadVideo))
	app.Get("/api/user/{userId}", app.handleRequest(handlers.GetUserDetails))

	// Search Routes
	app.Get("/api/search/{substring}", app.handleRequest(handlers.SearchForUser))

}

// Run app on router
func (app *App) Run(port string) {
	log.Fatal(http.ListenAndServe(port, app.Router))
}

// GET Method router wrapper
func (app *App) Get(path string, f func(w http.ResponseWriter, r *http.Request)) {
	app.Router.HandleFunc(path, f).Methods("GET")
}

// POST method router wrapper
func (app *App) Post(path string, f func(w http.ResponseWriter, r *http.Request)) {
	app.Router.HandleFunc(path, f).Methods("POST")
}

// PUT method router wrapper
func (app *App) Put(path string, f func(w http.ResponseWriter, r *http.Request)) {
	app.Router.HandleFunc(path, f).Methods("PUT")
}

// DELETE method router wrapper
func (app *App) Delete(path string, f func(w http.ResponseWriter, r *http.Request)) {
	app.Router.HandleFunc(path, f).Methods("DELETE")
}

// Function type to pass db instance to handler
type RequestHandlerFunction func (db *mongo.Client, w http.ResponseWriter, r *http.Request)

// Returns a HandlerFunc with ResponseWriter and Request
func (app *App) handleRequest(handler RequestHandlerFunction) http.HandlerFunc {
	return func (w http.ResponseWriter, r *http.Request) {
		handler(app.DB, w, r)
	}
}
