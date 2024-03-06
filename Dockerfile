FROM golang:1.21@sha256:c82d4ad02c062cf2b393bf0374df26638c6fed3dfe52cdbd3635d4a7befab86e as builder

WORKDIR /app
COPY . /app

RUN go get -d -v

# Statically compile our app for use in a distroless container
RUN CGO_ENABLED=0 go build -ldflags="-w -s" -v -o app .

# A distroless container image with some basics like SSL certificates
# https://github.com/GoogleContainerTools/distroless
FROM gcr.io/distroless/static@sha256:9be3fcc6abeaf985b5ecce59451acbcbb15e7be39472320c538d0d55a0834edc

COPY --from=builder /app/app /app

ENTRYPOINT ["/app"]
