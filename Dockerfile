FROM golang:1.21@sha256:c82d4ad02c062cf2b393bf0374df26638c6fed3dfe52cdbd3635d4a7befab86e as builder

WORKDIR /app
COPY . /app

RUN go get -d -v

# Statically compile our app for use in a distroless container
RUN CGO_ENABLED=0 go build -ldflags="-w -s" -v -o app .

# A distroless container image with some basics like SSL certificates
# https://github.com/GoogleContainerTools/distroless
FROM gcr.io/distroless/static@sha256:072d78bc452a2998929a9579464e55067db4bf6d2c5f9cde582e33c10a415bd1

COPY --from=builder /app/app /app

ENTRYPOINT ["/app"]
