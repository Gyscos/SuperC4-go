package main

import "time"

type Player struct {
	Game *Game
	Id   int

	LastSeen time.Time
}

func NewPlayer(Id int) *Player {
	return &Player{
		Id:       Id,
		LastSeen: time.Now()}
}

func (p *Player) Tick() {
	p.LastSeen = time.Now()
}
