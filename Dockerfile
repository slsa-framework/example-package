FROM golang:1.20@sha256:52921e63cc544c79c111db1d8461d8ab9070992d9c636e1573176642690c14b5 as builder

WORKDIR /app
COPY . /app

RUN go get -d -v

# Statically compile our app for use in a distroless container
RUN CGO_ENABLED=0 go build -ldflags="-w -s" -v -o app .

# A distroless container image with some basics like SSL certificates
# https://github.com/GoogleContainerTools/distroless
FROM gcr.io/distroless/static@sha256:3c5767883bc3ad6c4ad7caf97f313e482f500f2c214f78e452ac1ca932e1bf7f

COPY --from=builder /app/app /app

ENTRYPOINT ["/app"]
