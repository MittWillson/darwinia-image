FROM ghcr.io/mittwillson/darwinia-builder-rust as planner
WORKDIR /app
COPY darwinia /app
RUN cargo chef prepare --recipe-path recipe.json

FROM ghcr.io/mittwillson/darwinia-builder-rust as cacher
WORKDIR /app
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json

FROM ghcr.io/mittwillson/darwinia-builder-rust as builder
WORKDIR /app
COPY darwinia /app
# Copy over the cached dependencies
COPY --from=cacher /app/target target
COPY --from=cacher /usr/local/cargo /usr/local/cargo
RUN cargo build --release

FROM alpine as runtime
WORKDIR /app

COPY --from=builder /app/target/release/darwinia /usr/local/bin
ENTRYPOINT ["darwinia"]