# CGO-free static build.
# Base images are pinned by digest (multi-arch index) so a rebuild uses
# exactly the tested image; Dependabot (docker) bumps the digests.
FROM golang:1.27.3@sha256:e519d3b0a5b285e5aa53ab9eef02bc6bbb9cb04608389b743a136a9ce75f0d1e AS build
WORKDIR /src
COPY go.mod go.sum ./
COPY cmd ./cmd
COPY internal ./internal
ARG VERSION=dev
RUN CGO_ENABLED=0 go build -trimpath \
    -ldflags="-s -w -X main.version=${VERSION}" \
    -o /out/affiliate-engine ./cmd/affiliate-engine \
 && mkdir -p -m 0700 /out/data

FROM gcr.io/distroless/static-debian12:nonroot@sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab
COPY --from=build /out/affiliate-engine /affiliate-engine
# /data holds the SQLite db and the generated signing secret: owned by the
# distroless nonroot user (65532) and private, so a fresh named volume is
# writable by the engine and nobody else.
COPY --from=build --chown=65532:65532 /out/data /data
VOLUME ["/data"]
EXPOSE 8080
ENTRYPOINT ["/affiliate-engine", "-listen", ":8080", "-db", "sqlite:/data/affiliate-engine.db"]
