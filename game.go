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

type Point struct {
	X, Y int
}

type Game struct {
	sync.Mutex
	Cond *sync.Cond

	GameSize int
	Board    []int
	Players  [2]*Player

	State         GameState
	CurrentPlayer int

	LastMove Point
}

func NewGame(gameSize int) *Game {
	game := &Game{
		GameSize: gameSize,
		Board:    make([]int, gameSize*gameSize),
		State:    StatePlaying,
		LastMove: Point{-1, -1}}
	game.Cond = sync.NewCond(game)
	return game
}

func (g *Game) Play(x, y int) error {
	err := g.IsValidPlay(x, y)
	if err != nil {
		return err
	}

	g.SetCell(x, y, g.CurrentPlayer+1)
	g.LastMove = Point{x, y}

	if g.IsWinningMove(x, y) {
		g.State = StateOver
	} else {
		g.NextPlayer()
	}
	return nil
}

func (g *Game) SetCell(x, y int, value int) {
	g.Board[x+y*g.GameSize] = value
}

func (g *Game) IsWinningMove(x, y int) bool {
	v := g.CurrentPlayer + 1
	// Horizontal
	if 1+g.CountCells(x, y, 1, 0, v)+g.CountCells(x, y, -1, 0, v) >= 4 {
		return true
	}
	// Vertical
	if 1+g.CountCells(x, y, 0, 1, v)+g.CountCells(x, y, 0, -1, v) >= 4 {
		return true
	}
	// Diagonal
	if 1+g.CountCells(x, y, 1, 1, v)+g.CountCells(x, y, -1, -1, v) >= 4 {
		return true
	}
	// Anti-Diagonal
	if 1+g.CountCells(x, y, -1, 1, v)+g.CountCells(x, y, 1, -1, v) >= 4 {
		return true
	}

	return false
}

func (g *Game) CountCells(cx, cy int, dx, dy int, value int) int {
	sum := 0
	for i := 1; i < g.GameSize; i++ {
		nx := cx + i*dx
		ny := cy + i*dy
		if !g.IsInBounds(nx, ny) {
			break
		}
		if g.GetCell(nx, ny) != value {
			break
		}
		sum++
	}
	return sum
}

func (g *Game) GetCell(x, y int) int {
	return g.Board[x+y*g.GameSize]
}

func (g *Game) NextPlayer() {
	g.CurrentPlayer = 1 - g.CurrentPlayer
}

func (g *Game) GetCurrentPlayer() *Player {
	return g.Players[g.CurrentPlayer]
}

func (g *Game) IsInBounds(x, y int) bool {
	return x >= 0 && y >= 0 && x < g.GameSize && y < g.GameSize
}

func (g *Game) HasFreeCell(cx, cy int, dx, dy int) bool {
	for i := 1; i < g.GameSize; i++ {
		nx := cx + i*dx
		ny := cy + i*dy
		if !g.IsInBounds(nx, ny) {
			break
		}
		if g.GetCell(nx, ny) == 0 {
			return true
		}
	}
	return false
}

func (g *Game) IsValidPlay(x, y int) error {
	if !g.IsInBounds(x, y) {
		return errors.New("target is out of bounds")
	}
	if g.GetCell(x, y) != 0 {
		return errors.New("target cell is not empty")
	}

	// Check in all directions...
	if g.HasFreeCell(x, y, 1, 0) &&
		g.HasFreeCell(x, y, -1, 0) &&
		g.HasFreeCell(x, y, 0, 1) &&
		g.HasFreeCell(x, y, 0, -1) {
		return errors.New("target is not a valid move")
	}

	return nil
}
