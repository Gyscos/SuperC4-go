package main

import (
	"encoding/json"
	"errors"
	"log"
	"math/rand"
	"net/http"
	"strconv"
	"sync"
	"time"
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
	PlayerId  int
	GameSize  int
	FirstMove bool
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
	go s.clearGhosts()
	return s
}

func (s *Server) clearGhosts() {
	timeout := 10 * time.Minute
	for {
		time.Sleep(timeout)
		log.Println("Clearing ghosts...")
		s.clearGhostsOnce(timeout)
	}
}

func (s *Server) clearGhost(p *Player) {
	p.Game.Lock()
	defer p.Game.Unlock()

	log.Println("Clearing ghost player:", p.Id)

	p.Game.State = StateCancelled
	p.Game.Cond.Broadcast()

	delete(s.Players, p.Id)
}

func (s *Server) clearGhostsOnce(timeout time.Duration) {
	s.Lock()
	defer s.Unlock()

	for _, p := range s.Players {
		if time.Since(p.LastSeen) > timeout {
			s.clearGhost(p)
		}
	}
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
			r1.Success <- JoinSuccess{id1, gameSize, true}
			r2.Success <- JoinSuccess{id2, gameSize, false}
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
		id := rand.Intn(1000000)
		if _, ok := s.Players[id]; !ok {
			s.Players[id] = NewPlayer(id)
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
	p.Tick()

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

func (s *Server) handleWait(notify <-chan bool, idStr string) (state GameState, move Point, victory bool, err error) {
	// Ok, this function is a mess.
	// The goal is to wait on a condition, and also on a channel
	// Unfortunately the select statement won't allow for a Wait() case
	// So instead, we listen for the channel in a goroutine, and
	// wake up the condition when something arrives.
	// But unfortunately, the channel is not closed if the request is
	// not cancelled. So we have to make this goroutine stop when
	// everything goes smoothly. Ugh.

	p, err := s.findPlayer(idStr)
	if err != nil {
		return
	}
	p.Tick()

	p.Game.Lock()
	defer p.Game.Unlock()

	// Of course, the timeout must be timeouted when no longer needed
	timeoutTimer := make(chan struct{}, 1)
	timeouted := false

	// Start a timeout goroutine
	go func() {
		// Cancel the wait if we disconnected.
		select {
		case <-notify:
			// Lock, so we don't wake it until the other routine is waiting
			p.Game.Lock()
			defer p.Game.Unlock()

			timeouted = true
			p.Game.Cond.Broadcast()
		case <-timeoutTimer:
		}

	}()

	for !timeouted && p.Game.State == StatePlaying && p.Game.GetCurrentPlayer() != p {
		p.Game.Cond.Wait()
	}

	timeoutTimer <- struct{}{}

	// Is it our turn to play ?
	state = p.Game.State

	// We're done waiting when a player played or left.

	if state == StateCancelled {
		err = errors.New("the other player left")
		return
	}

	move = p.Game.LastMove
	victory = (state == StateOver && p.Game.GetCurrentPlayer() == p)
	return
}

func (s *Server) handleResume(idStr string) ([]int, int, error) {
	p, err := s.findPlayer(idStr)
	if err != nil {
		return nil, 0, err
	}
	p.Tick()

	p.Game.Lock()
	defer p.Game.Unlock()

	// Make a copy, so it won't be modified when we drop the lock
	board := make([]int, len(p.Game.Board))
	copy(board, p.Game.Board)
	return board, p.Game.GameSize, nil
}

func (s *Server) joinHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	// Create a user, wait for a match.
	notify := w.(http.CloseNotifier).CloseNotify()
	// TODO: handle different opponent types (human, AI, ...)
	success, err := s.handleJoin(notify)
	if err != nil {
		return
	}
	log.Println("Success!", strconv.Itoa(success.PlayerId))

	msg := struct {
		// PlayerId is the player's token to keep playing.
		PlayerId int
		// Currently, GameSize will always be 8. Here for future-proofing (??).
		GameSize int
		// FirstMove is TRUE if this player must play first.
		FirstMove bool
	}{
		success.PlayerId,
		success.GameSize,
		success.FirstMove,
	}
	json.NewEncoder(w).Encode(msg)
}

func (s *Server) resumeHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
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
	// WaitHandler returns when one of these cases is true:
	// * The game was cancelled: Success=false
	// * The game is over (somebody has won): GameOver=true
	// * It is the caller's turn to play

	w.Header().Set("Access-Control-Allow-Origin", "*")
	notify := w.(http.CloseNotifier).CloseNotify()
	state, p, victory, err := s.handleWait(notify, r.FormValue("id"))
	msg := struct {
		// Error describes the error, if there is one.
		Error string
		// Success is TRUE if there was no error
		Success bool
		// GameOver is TRUE if the game was won
		GameOver bool
		// Victory if TRUE if the player won
		Victory bool
		// Last move by the opponent
		X, Y int
	}{
		readErr(err),
		err == nil,
		state == StateOver,
		victory,
		p.X, p.Y,
	}
	json.NewEncoder(w).Encode(msg)
}

func (s *Server) leaveHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	err := s.handleLeave(r.FormValue("id"))

	// Pack to json and send !
	// Although most of the time, he won't care about the answer...
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
	w.Header().Set("Access-Control-Allow-Origin", "*")
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
