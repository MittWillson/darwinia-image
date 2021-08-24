FROM ghcr.io/mittwillson/darwinia-builder-rust as base

FROM base as planner
WORKDIR /app
COPY darwinia /app
RUN cargo chef prepare --recipe-path recipe.json

FROM base as cacher
WORKDIR /app
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json

FROM base as builder
WORKDIR /app
COPY darwinia /app
# Copy over the cached dependencies
COPY --from=cacher /app/target target
COPY --from=cacher /usr/local/cargo /usr/local/cargo
RUN cargo build --release

FROM debian:buster-slim as runtime
WORKDIR /app

COPY --from=builder /app/target/release/darwinia /usr/local/bin/darwinia

EXPOSE 30333 9933 9944

ENTRYPOINT ["darwinia"]