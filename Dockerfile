FROM golang:1.21@sha256:f2eb989b0b5579b75652b72ee7b3b04cb1736fc254d7efbf3e492d4c9ea7235a as builder

WORKDIR /app
COPY . /app

RUN go get -d -v

# Statically compile our app for use in a distroless container
RUN CGO_ENABLED=0 go build -ldflags="-w -s" -v -o app .

# A distroless container image with some basics like SSL certificates
# https://github.com/GoogleContainerTools/distroless
FROM gcr.io/distroless/static@sha256:ce46866b3a5170db3b49364900fb3168dc0833dfb46c26da5c77f22abb01d8c3

COPY --from=builder /app/app /app

ENTRYPOINT ["/app"]
