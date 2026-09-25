# KollioServer runs on Linux. A macOS-built binary is never reused.
FROM swift:6.2-jammy AS build
WORKDIR /src
COPY services/KollioServer/Package.swift services/KollioServer/Package.swift
COPY services/KollioServer/Sources services/KollioServer/Sources
COPY packages/KollioCore/Package.swift packages/KollioCore/Package.swift
COPY packages/KollioCore/Sources packages/KollioCore/Sources
RUN swift build -c release --product kollio-server

FROM debian:bookworm-slim
RUN useradd --create-home --shell /usr/sbin/nologin kollio
COPY --from=build /src/.build/release/kollio-server /usr/local/bin/kollio-server
USER kollio
ENV KOLLIO_BIND=0.0.0.0 KOLLIO_PORT=8080
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/kollio-server"]
