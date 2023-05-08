ARG BASE_IMAGE=node:18-alpine
FROM ${BASE_IMAGE} as base

# Needed for running the docker container on M1/M2 because ARM images are different?!
RUN apk add --update python3 make g++ && rm -rf /var/cache/apk/*
###

RUN mkdir /app
WORKDIR /app

# Required for building the api and web distributions
ENV NODE_ENV production


FROM base as dependencies

COPY .yarn .yarn
COPY .yarnrc.yml .yarnrc.yml
COPY package.json package.json
COPY web/package.json web/package.json
COPY api/package.json api/package.json

COPY yarn.lock yarn.lock

RUN --mount=type=cache,target=/root/.yarn/berry/cache \
    --mount=type=cache,target=/root/.cache yarn install --immutable

COPY redwood.toml .
COPY graphql.config.js .

FROM dependencies as web_build

COPY api api
COPY web web
RUN yarn rw build web

FROM dependencies as api_build

COPY api api
RUN yarn rw build api

### ⚠️ So that we can seed the database temporarily - this is not recommended!
### We are only doing this for our demo app
COPY scripts scripts
##########################

FROM dependencies

ENV NODE_ENV development

COPY --from=web_build /app/web/dist /app/web/dist
COPY --from=api_build /app/api /app/api
COPY --from=api_build /app/node_modules/.prisma /app/node_modules/.prisma

COPY .fly .fly

ENTRYPOINT ["sh"]
CMD [".fly/start.sh"]
