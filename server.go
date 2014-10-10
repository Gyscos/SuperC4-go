package main

import (
	"encoding/json"
	"errors"
	"log"
	"math/rand"
	"net/http"
	"strconv"
	"sync"
)

func readErr(err error) string {
	if err == nil {
		return ""
	} else {
		return err.Error()
	}
}

type Server struct {
	sync.Mutex

	Players map[int]*Player

	Queue chan *JoinRequest
}

type JoinSuccess struct {
	PlayerId int
	GameSize int
}

type JoinRequest struct {
	Cancel  chan struct{}
	Success chan JoinSuccess
}

func NewJoinRequest() *JoinRequest {
	return &JoinRequest{
		Cancel:  make(chan struct{}),
		Success: make(chan JoinSuccess)}
}

func NewServer() *Server {
	s := &Server{
		Players: make(map[int]*Player),
		Queue:   make(chan *JoinRequest, 10)}
	go s.matchMaking()
	return s
}

func (s *Server) matchMaking() {
	gameSize := 8

	for {
		r1 := <-s.Queue

		select {
		case <-r1.Cancel:
			continue
		case r2 := <-s.Queue:
			// Success !
			id1, id2 := s.createGame(gameSize)
			r1.Success <- JoinSuccess{id1, gameSize}
			r2.Success <- JoinSuccess{id2, gameSize}
		}
	}
}

func (s *Server) removePlayer(player *Player) {
	s.Lock()
	defer s.Unlock()

	delete(s.Players, player.Id)
}

func (s *Server) createPlayer() int {
	s.Lock()
	defer s.Unlock()

	for {
		id := rand.Int()
		if _, ok := s.Players[id]; !ok {
			s.Players[id] = &Player{Id: id}
			return id
		}
	}
}

func (s *Server) createGame(gameSize int) (int, int) {
	id1 := s.createPlayer()
	id2 := s.createPlayer()
	game := NewGame(gameSize)
	game.Players[0] = s.Players[id1]
	game.Players[1] = s.Players[id2]
	s.Players[id1].Game = game
	s.Players[id2].Game = game

	return id1, id2
}

func (s *Server) findPlayer(idStr string) (*Player, error) {
	// Find the player ID
	pId, err := strconv.Atoi(idStr)
	if err != nil {
		return nil, errors.New("cannot read player id")
	}

	// Find the player
	p, ok := s.Players[pId]
	if !ok {
		return nil, errors.New("player id is invalid")
	}

	return p, nil
}

func (s *Server) handlePlay(pStr, xStr, yStr string) error {

	p, err := s.findPlayer(pStr)
	if err != nil {
		return err
	}

	// Find his command
	x, err := strconv.Atoi(xStr)
	if err != nil {
		return errors.New("cannot read target cell")
	}

	y, err := strconv.Atoi(yStr)
	if err != nil {
		return errors.New("cannot read target cell")
	}

	// Find his game
	g := p.Game
	if g == nil {
		return errors.New("cannot find player game (!!)")
	}

	g.Lock()
	defer g.Unlock()

	if g.State == StateOver {
		return errors.New("game is over")
	} else if g.State == StateCancelled {
		return errors.New("the other player left")
	}

	if g.GetCurrentPlayer() != p {
		return errors.New("it is not the player's turn")
	}

	// Try to play
	err = g.Play(x, y)
	if err != nil {
		return err
	}

	// Ok, the other player can play.
	g.Cond.Broadcast()

	return nil
}

func (s *Server) handleLeave(idStr string) error {
	p, err := s.findPlayer(idStr)
	if err != nil {
		return err
	}

	p.Game.Lock()
	defer p.Game.Unlock()

	s.removePlayer(p)

	p.Game.State = StateCancelled

	p.Game.Cond.Broadcast()

	return nil
}

func (s *Server) handleJoin(notify <-chan bool) (JoinSuccess, error) {
	req := NewJoinRequest()
	s.Queue <- req

	select {
	case <-notify:
		req.Cancel <- struct{}{}
	case success := <-req.Success:
		// Cool !
		return success, nil

	}

	return JoinSuccess{}, errors.New("Cancelled request")
}

func (s *Server) handleWait(idStr string) (GameState, error) {
	p, err := s.findPlayer(idStr)
	if err != nil {
		return 0, err
	}

	p.Game.Lock()
	defer p.Game.Unlock()

	if p.Game.State == StatePlaying && p.Game.GetCurrentPlayer() != p {
		p.Game.Cond.Wait()
	}
	// Is it our turn to play ?

	// We're done waiting when a player played or left.

	if p.Game.State == StateCancelled {
		return p.Game.State, errors.New("the other player left")
	}

	return p.Game.State, nil
}

func (s *Server) handleResume(idStr string) ([]int, int, error) {
	p, err := s.findPlayer(idStr)
	if err != nil {
		return nil, 0, err
	}

	p.Game.Lock()
	defer p.Game.Unlock()

	// Make a copy, so it won't be modified when we drop the lock
	board := make([]int, len(p.Game.Board))
	copy(board, p.Game.Board)
	return board, p.Game.GameSize, nil
}

func (s *Server) joinHandler(w http.ResponseWriter, r *http.Request) {
	// Create a user, wait for a match.
	notify := w.(http.CloseNotifier).CloseNotify()
	success, err := s.handleJoin(notify)
	if err != nil {
		return
	}

	msg := struct {
		PlayerId int
		GameSize int
	}{
		success.PlayerId,
		success.GameSize,
	}
	json.NewEncoder(w).Encode(msg)
}

func (s *Server) resumeHandler(w http.ResponseWriter, r *http.Request) {
	board, gameSize, err := s.handleResume(r.FormValue("id"))
	msg := struct {
		Error    string
		Success  bool
		Board    []int
		GameSize int
	}{
		readErr(err),
		err == nil,
		board,
		gameSize,
	}
	json.NewEncoder(w).Encode(msg)
}

func (s *Server) waitHandler(w http.ResponseWriter, r *http.Request) {
	state, err := s.handleWait(r.FormValue("id"))
	msg := struct {
		Error    string
		Success  bool
		GameOver bool
	}{
		readErr(err),
		err == nil,
		state == StateOver,
	}
	json.NewEncoder(w).Encode(msg)
}

func (s *Server) leaveHandler(w http.ResponseWriter, r *http.Request) {
	err := s.handleLeave(r.FormValue("id"))

	// Pack to json and send !
	msg := struct {
		Error   string
		Success bool
	}{
		readErr(err),
		err == nil,
	}
	json.NewEncoder(w).Encode(msg)
}

func (s *Server) playHandler(w http.ResponseWriter, r *http.Request) {
	err := s.handlePlay(r.FormValue("id"), r.FormValue("x"), r.FormValue("y"))
	// Pack to json and send !
	msg := struct {
		Error   string
		Success bool
	}{
		readErr(err),
		err == nil,
	}
	json.NewEncoder(w).Encode(msg)
}

/// Now, debug API

func (s *Server) listPlayersHandler(w http.ResponseWriter, r *http.Request) {
	s.Lock()
	defer s.Unlock()
	log.Println("Listing players")

	msg := struct{ Players map[string]int }{make(map[string]int)}
	for k, v := range s.Players {
		log.Println("Adding a player", k)
		msg.Players[strconv.Itoa(k)] = v.Id
	}
	json.NewEncoder(w).Encode(msg)
}
