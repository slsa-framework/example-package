FROM golang:1.20@sha256:74a382917f6eaa7cc2d000dc2cd412a7f823f343b3b6268b20d84d057bc56718 as builder

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
