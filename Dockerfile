FROM golang:1.21@sha256:c82d4ad02c062cf2b393bf0374df26638c6fed3dfe52cdbd3635d4a7befab86e as builder

WORKDIR /app
COPY . /app

RUN go get -d -v

# Statically compile our app for use in a distroless container
RUN CGO_ENABLED=0 go build -ldflags="-w -s" -v -o app .

# A distroless container image with some basics like SSL certificates
# https://github.com/GoogleContainerTools/distroless
FROM gcr.io/distroless/static@sha256:6d31326376a7834b106f281b04f67b5d015c31732f594930f2ea81365f99d60c

COPY --from=builder /app/app /app

ENTRYPOINT ["/app"]
