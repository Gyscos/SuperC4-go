package main

import (
	"log"
	"testing"
)

func TestServer(t *testing.T) {
	s := NewServer()

	eC := make(chan error, 5)
	sC := make(chan bool)

	go func() {
		notify := make(chan bool)
		success, err := s.handleJoin(notify)
		if err != nil {
			eC <- err
		}
		log.Println(success.PlayerId)
		sC <- true
	}()

	go func() {
		notify := make(chan bool)
		_, err := s.handleJoin(notify)
		if err != nil {
			eC <- err
		}
		sC <- true
	}()

	for i := 0; i < 2; i++ {
		select {
		case <-sC:
			// Good!
		case err := <-eC:
			t.Error(err)
		}
	}
}
