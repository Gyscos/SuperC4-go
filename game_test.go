package main

import "testing"

func TestGame(t *testing.T) {
	g := NewGame(8)

	plays := []struct {
		x, y int
	}{
		{0, 4},
		{1, 4},
		{0, 5},
		{0, 6},
	}

	if g.Play(5, 5) == nil {
		t.Error("Error: 5,5 should not be a valid move")
	}

	for _, play := range plays {
		err := g.Play(play.x, play.y)
		if err != nil {
			t.Error(play, err)
		}
	}
}
