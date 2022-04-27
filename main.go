package main

import (
	"fmt"
	"strings"

	"github.com/pborman/uuid"
)

var (
	gitVersion   string
	gitSomething string
)

func main() {
	uuidWithHyphen := uuid.NewRandom()
	uuid := strings.Replace(uuidWithHyphen.String(), "-", "", -1)

	fmt.Println("GitVersion:", gitVersion)
	fmt.Println("GitSomething:", gitSomething)
	fmt.Println("Hello world:", uuid)
}
