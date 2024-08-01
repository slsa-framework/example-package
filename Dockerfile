FROM golang:1.21@sha256:f2eb989b0b5579b75652b72ee7b3b04cb1736fc254d7efbf3e492d4c9ea7235a as builder

WORKDIR /app
COPY . /app

RUN go get -d -v

# Statically compile our app for use in a distroless container
RUN CGO_ENABLED=0 go build -ldflags="-w -s" -v -o app .

# A distroless container image with some basics like SSL certificates
# https://github.com/GoogleContainerTools/distroless
FROM gcr.io/distroless/static@sha256:41972110a1c1a5c0b6adb283e8aa092c43c31f7c5d79b8656fbffff2c3e61f05

COPY --from=builder /app/app /app

ENTRYPOINT ["/app"]
