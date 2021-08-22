FROM --platform=$TARGETPLATFORM rust as base
WORKDIR /app
RUN apt-get update && \
  apt-get install -y cmake pkg-config libssl-dev git clang libclang-dev && \
  rm -rf /var/lib/apt/lists/*
RUN rustup update && rustup default nightly && rustup update nightly
RUN rustup target add wasm32-unknown-unknown
RUN cargo install cargo-chef 

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

FROM alpine as runtime
WORKDIR /app

COPY --from=builder /app/target/release/darwinia /usr/local/bin
ENTRYPOINT ["darwinia"]