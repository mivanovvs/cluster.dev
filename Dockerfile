ARG HELMFILE_VERSION=0.113.0

FROM golang:1.14.2-alpine3.11 as builder

RUN apk add --no-cache make git bash
WORKDIR /workspace/cluster-dev
COPY . /workspace/cluster-dev
RUN make

FROM hashicorp/terraform:light as terraform

### Install Helmfile
# Image pulled from https://hub.docker.com/r/chatwork/helmfile/dockerfile
# TODO create own image with terraform and helmfile versioning

FROM chatwork/helmfile:$HELMFILE_VERSION
ARG YAMLTOENV_VERSION=v0.0.3

COPY --from=terraform /bin/terraform /bin/terraform
COPY --from=builder /workspace/cluster-dev/bin/reconciler /bin/reconciler

### Install s3cmd
RUN python3 -m pip install --upgrade pip && \
    pip3 install --no-cache-dir --upgrade s3cmd && \
    curl -L  https://github.com/shalb/yamltoenv/releases/download/${YAMLTOENV_VERSION}/yamltoenv_${YAMLTOENV_VERSION}_linux_amd64.tgz |  tar -xvz \
    && rm -f yamltoenv_${YAMLTOENV_VERSION}_linux_amd64.tgz && mv yamltoenv /bin/

ENV PRJ_ROOT /app
WORKDIR $PRJ_ROOT

# Look on .dockerignore file to check what included
COPY . .

ENTRYPOINT ["/bin/reconciler"]
