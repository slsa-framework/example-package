// main package
package main

import (
	"flag"
	"fmt"
	"os"
	"strings"

	"github.com/pborman/uuid"
)

var (
	gitVersion    string
	gitCommit     string
	gitBranch     string
	gitTag        string
	filenameFlags arrayFlags
)

type arrayFlags []string

func (i *arrayFlags) String() string {
	return strings.Join(*i, ", ")
}

func (i *arrayFlags) Set(value string) error {
	*i = append(*i, value)
	return nil
}

func main() {
	uuidWithHyphen := uuid.NewRandom()
	uuidWithoutHyphen := strings.ReplaceAll(uuidWithHyphen.String(), "-", "")

	fmt.Println("GitBranch:", gitBranch)
	fmt.Println("GitTag:", gitTag)
	fmt.Println("GitVersion:", gitVersion)
	fmt.Println("GitCommit:", gitCommit)
	fmt.Println("Hello world:", uuidWithoutHyphen)

	// To test the container-based builder workflows, this App may also create a file with
	// specified contents if provided any filename arguments.
	flag.Var(&filenameFlags, "filename", "a filename to write out")
	content := flag.String("content", "default", "content to write to the file")
	flag.Parse()

	for _, filename := range filenameFlags {
		fmt.Println("Writing to filename: ", filename)
		if err := os.WriteFile(filename, []byte(*content), 0o600); err != nil {
			fmt.Println("error writing to file: %w", err)
			panic(err)
		}
	}
}
