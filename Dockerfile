FROM golang:latest as builder

WORKDIR $GOPATH/src

RUN git clone -b yagpdb https://github.com/jantsop/discordgo github.com/jantsop/discordgo \
  && git clone -b dgofork https://github.com/jantsop/dutil github.com/jantsop/dutil \
  && git clone -b dgofork https://github.com/jantsop/dshardmanager github.com/jantsop/dshardmanager \
  && git clone -b dgofork https://github.com/jantsop/dcmd github.com/jantsop/dcmd

# Fix some fucked up shit coding
RUN git clone -b v2 https://github.com/jantsop/dshardorchestrator/ $GOPATH/srcgithub.com/jantsop/dshardorchestrator/v2
RUN git clone -b master https://github.com/jantsop/sqlboiler/ $GOPATH/src/github.com/jantsop/sqlboiler/

RUN go get -d -v \
  github.com/jantsop/yagpdb/cmd/yagpdb
RUN CGO_ENABLED=0 GOOS=linux go install -v \
  github.com/jantsop/yagpdb/cmd/yagpdb

FROM alpine:latest

ENTRYPOINT ["/app/yagpdb"]
CMD ["-all", "-pa", "-exthttps=false", "-https=true"]

WORKDIR /app
VOLUME \
  /app/soundboard \
  /app/cert \
  /app/gauth
EXPOSE 80 443

RUN apk --no-cache add ca-certificates ffmpeg tzdata

# Handle templates for plugins automatically
COPY --from=builder /go/src/github.com/jantsop/yagpdb/*/assets/*.html templates/plugins/

COPY --from=builder /go/src/github.com/jantsop/yagpdb/cmd/yagpdb/templates templates/
COPY --from=builder /go/src/github.com/jantsop/yagpdb/cmd/yagpdb/posts posts/
COPY --from=builder /go/src/github.com/jantsop/yagpdb/cmd/yagpdb/static static/

COPY --from=builder /go/bin/yagpdb .
