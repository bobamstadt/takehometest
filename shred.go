// shred
//
// Author: Robert Amstadt
//
package main

import (
	"os"
	"log"
	"math/rand"
	"encoding/binary"
)

func main() {
	if len(os.Args) != 2 {
		println("Usage: shred filename")
		os.Exit(1)
	}

	Shred(os.Args[1])
}

func Shred(path string) {
	shred1(path)
	shred1(path)
	shred1(path)
}

func shred1(filename string) {
	// We want to overwrite a file to erase it.  This means that we need to be
	// certain that the file blocks are overwritten and not freed.  We will assume
	// that if we open the file for read/write WITHOUT truncation, that when we
	// write we will overwrite the existing blocks.  We will also need to sync caches
	// so that writes are fully committed to the storage device.

	shredfile, err := os.OpenFile(filename, os.O_RDWR, 0644)
	if err != nil {
		log.Fatal(err)
	}

	// Need to get the length of the file to know how much to write.
	shredinfo, err := shredfile.Stat()
	if err != nil {
		log.Fatal(err)
	}
	shredlen := shredinfo.Size()

	// Allocate byte array for writes.
	ba := make([]byte, 8)

	// Run through the entire length of the file.
	for i := int64(0); i < shredlen; i += 8 {
		// Get a random number 8 bytes at a time
		r := rand.Uint64()
		binary.LittleEndian.PutUint64(ba, r)

		// If less than 8 bytes left to write then write a reduced amount.
		// Otherwise write the entire 8 bytes.
		if shredlen - i < 8 {
			_, err := shredfile.Write(ba[0:shredlen - i])
			if err != nil {
				log.Fatal(err)
			}
		} else {
			_, err := shredfile.Write(ba)
			if err != nil {
				log.Fatal(err)
			}
		}
	}

	// fsync() on the system to commit caches to disk
	shredfile.Sync()
	shredfile.Close()
}
