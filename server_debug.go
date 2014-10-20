package main

import (
	"encoding/json"
	"log"
	"net/http"
)

/// Now, debug API

func (s *Server) debugStatusHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")

	s.Lock()
	defer s.Unlock()
	log.Println("Listing players")

	msg := struct {
		Players []int

		PlayersInQueue int
	}{
		nil,
		len(s.Queue),
	}

	for k, v := range s.Players {
		log.Println("Adding a player", k)
		msg.Players = append(msg.Players, v.Id)
	}

	bytes, err := json.MarshalIndent(msg, "", "    ")
	if err != nil {
		log.Println("Error:", err)
		return
	}
	w.Write(bytes)
}
