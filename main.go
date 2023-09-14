package main

import (
	"log"

	"github.com/valyala/fasthttp"
)

func main() {
	h := requestHandler
	if err := fasthttp.ListenAndServe(":8080", h); err != nil {
		log.Fatalf("Error in ListenAndServe: %s", err)
	}
}

func requestHandler(ctx *fasthttp.RequestCtx) {
	switch string(ctx.Path()) {
	case "/":
		ctx.WriteString("Hello world")
	default:
		ctx.Error("Unsupported path", fasthttp.StatusNotFound)
	}
}
