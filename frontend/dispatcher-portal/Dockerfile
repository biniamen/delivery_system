FROM node:20.19-alpine AS build
WORKDIR /app
RUN corepack enable && corepack prepare pnpm@11.19.0 --activate
COPY frontend/dispatcher-portal/package.json frontend/dispatcher-portal/pnpm-lock.yaml frontend/dispatcher-portal/pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile
COPY frontend/dispatcher-portal/ .
RUN pnpm build:production

FROM nginx:1.29-alpine AS final
COPY frontend/dispatcher-portal/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist/dispatcher-portal/browser /usr/share/nginx/html
EXPOSE 8080
