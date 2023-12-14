# trunk-ignore-all(trivy/DS002,trivy/DS026,checkov/CKV_DOCKER_2,checkov/CKV_DOCKER_3)
FROM alpine:3.19@sha256:51b67269f354137895d43f3b3d810bfacd3945438e94dc5ac55fdac340352f48 as SOURCE

RUN apk upgrade --no-cache

FROM scratch

COPY --from=SOURCE / /

