package main

import (
	"errors"
	"sync"
)

type GameState int

const (
	StatePlaying GameState = iota
	StateCancelled
	StateOver
)

type Game struct {
	sync.Mutex
	Cond *sync.Cond

	GameSize int
	Board    []int
	Players  [2]*Player

	State         GameState
	CurrentPlayer int
}

func NewGame(gameSize int) *Game {
	game := &Game{
		GameSize: gameSize,
		Board:    make([]int, gameSize*gameSize),
		State:    StatePlaying}
	game.Cond = sync.NewCond(game)
	return game
}

func (g *Game) Play(x, y int) error {
	if !g.IsValidPlay(x, y) {
		return errors.New("target cell is not a valid move")
	}

	g.NextPlayer()
	return nil
}

func (g *Game) NextPlayer() {
	g.CurrentPlayer = 1 - g.CurrentPlayer
}

func (g *Game) GetCurrentPlayer() *Player {
	return g.Players[g.CurrentPlayer]
}

func (g *Game) IsValidPlay(x, y int) bool {
	if x < 0 || y < 0 || x >= g.GameSize || y >= g.GameSize {
		return false
	}
	return true
}
