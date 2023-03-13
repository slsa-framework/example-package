FROM golang:1.20@sha256:52921e63cc544c79c111db1d8461d8ab9070992d9c636e1573176642690c14b5 as builder

WORKDIR /app
COPY . /app

RUN go get -d -v

# Statically compile our app for use in a distroless container
RUN CGO_ENABLED=0 go build -ldflags="-w -s" -v -o app .

# A distroless container image with some basics like SSL certificates
# https://github.com/GoogleContainerTools/distroless
FROM gcr.io/distroless/static@sha256:97b762efb017cbbabf566046852de8049f84f73e168282d06da316851c7ef263

COPY --from=builder /app/app /app

ENTRYPOINT ["/app"]
