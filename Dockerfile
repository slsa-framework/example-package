FROM golang:1.21@sha256:d83472f1ab5712a6b2b816dc811e46155e844ddc02f5f5952e72c6deedafed77 as builder

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
