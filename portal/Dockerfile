# syntax=docker/dockerfile:1
# Imagen del portal (Backstage). Compilación multietapa: solo necesita Docker, igual en local que
# en GitHub Actions (.github/workflows/portal.yaml). Imágenes base fijadas por digest (RNF-01).

# --- 1. Compilación: dependencias, comprobación de tipos y bundle del backend (incluye el frontend)
FROM node:24-bookworm-slim@sha256:d6aa754f16b3197301076f047b5def2f02ea1dbbc2ca920407d46d7ec7f87b20 AS build
ENV YARN_ENABLE_TELEMETRY=0
WORKDIR /app
COPY .yarn ./.yarn
COPY .yarnrc.yml package.json yarn.lock backstage.json tsconfig.json ./
COPY packages ./packages
COPY plugins ./plugins
RUN --mount=type=cache,target=/root/.yarn/berry/cache \
    yarn install --immutable
COPY app-config*.yaml ./
RUN yarn tsc && yarn build:backend

# --- 2. Ejecución: dependencias de producción + mkdocs para TechDocs (generación local)
FROM node:24-bookworm-slim@sha256:d6aa754f16b3197301076f047b5def2f02ea1dbbc2ca920407d46d7ec7f87b20
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 python3-venv \
    && rm -rf /var/lib/apt/lists/* \
    && python3 -m venv /opt/techdocs \
    && /opt/techdocs/bin/pip install --no-cache-dir mkdocs-techdocs-core==1.7.1
ENV PATH=/opt/techdocs/bin:$PATH \
    NODE_ENV=production \
    YARN_ENABLE_TELEMETRY=0

USER node
WORKDIR /app
COPY --from=build --chown=node:node /app/.yarn ./.yarn
COPY --from=build --chown=node:node /app/.yarnrc.yml /app/package.json /app/yarn.lock /app/backstage.json ./
COPY --from=build --chown=node:node /app/packages/backend/dist/skeleton.tar.gz ./
RUN tar xzf skeleton.tar.gz && rm skeleton.tar.gz
RUN --mount=type=cache,target=/home/node/.yarn,uid=1000,gid=1000 \
    yarn workspaces focus --all --production && rm -rf "$(yarn cache clean)"
COPY --from=build --chown=node:node /app/packages/backend/dist/bundle.tar.gz ./
COPY --from=build --chown=node:node /app/app-config.yaml /app/app-config.production.yaml ./
RUN tar xzf bundle.tar.gz && rm bundle.tar.gz

EXPOSE 7007
CMD ["node", "packages/backend", "--config", "app-config.yaml", "--config", "app-config.production.yaml"]
