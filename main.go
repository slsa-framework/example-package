package main

import (
	"fmt"
	"strings"

	"github.com/pborman/uuid"
)

var (
	gitVersion string
	gitCommit  string
	gitBranch  string
	gitTag     string
)

func main() {
	uuidWithHyphen := uuid.NewRandom()
	uuidWithoutHyphen := strings.ReplaceAll(uuidWithHyphen.String(), "-", "")

	fmt.Println("GitBranch:", gitBranch)
	fmt.Println("GitTag:", gitTag)
	fmt.Println("GitVersion:", gitVersion)
	fmt.Println("GitCommit:", gitCommit)
	fmt.Println("Hello world:", uuidWithoutHyphen)
}
