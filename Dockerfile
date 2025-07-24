# Dockerfile - Secure Anchor build
FROM rust:1.76-slim

RUN apt-get update && apt-get install -y libssl-dev pkg-config build-essential curl git

# Install Anchor CLI
RUN cargo install --git https://github.com/coral-xyz/anchor anchor-cli --locked

WORKDIR /app
COPY . .

RUN anchor build

CMD ["anchor", "test"]
