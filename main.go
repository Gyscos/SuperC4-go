package main

import (
	"flag"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"strconv"
)

var port = flag.Int("port", 8080, "HTTP port to listen to.")
var debug = flag.Bool("debug", false, "Activate debug API")

func mainHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello!")
}

func main() {
	flag.Parse()
	if flag.ErrHelp != nil {
		return
	}

	rand.Seed(42)

	// UI
	http.Handle("/", http.FileServer(http.Dir("js/web/")))

	s := NewServer()

	// API
	http.HandleFunc("/api/join", s.joinHandler)
	http.HandleFunc("/api/play", s.playHandler)
	http.HandleFunc("/api/wait", s.waitHandler)
	http.HandleFunc("/api/leave", s.leaveHandler)
	http.HandleFunc("/api/resume", s.resumeHandler)

	if *debug {
		log.Println("Warning: Debug API activated!! Do not use in production!")
		http.HandleFunc("/debug/list/players", s.listPlayersHandler)
	}

	log.Println("Listening to port", *port)
	err := http.ListenAndServe(":"+strconv.Itoa(*port), nil)
	if err != nil {
		log.Println("Error:", err)
	}
}
