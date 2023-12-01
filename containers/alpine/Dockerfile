# trunk-ignore-all(trivy/DS002,trivy/DS026,checkov/CKV_DOCKER_2,checkov/CKV_DOCKER_3)
FROM alpine:3.18@sha256:34871e7290500828b39e22294660bee86d966bc0017544e848dd9a255cdf59e0 as SOURCE

RUN apk upgrade --no-cache

FROM scratch

COPY --from=SOURCE / /

