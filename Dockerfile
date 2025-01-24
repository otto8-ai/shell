FROM ubuntu:24.04 AS base

RUN apt update && \
    apt install -y curl

COPY <<"EOF" /etc/distillery.yaml
bin_path: /usr/local/bin
path: /usr/local/share/dist
cache_path: /var/cache/dist
EOF

RUN curl --proto '=https' --tlsv1.2 -LsSf https://get.dist.sh/ | DISTILLERY_CONFIG=/etc/distillery.yaml sh

COPY <<"EOF" /root/Distfile
install aquasecurity/trivy
install asciinema/asciinema
install astral-sh/uv
install atuinsh/atuin
install caddyserver/caddy
install cli/cli
install coroot/coroot
install dagger/dagger
install defenseunicorns/uds-cli
install derailed/k9s
install digitalocean/doctl
install docker/compose
install ekristen/aws-nuke
install ekristen/azure-nuke
install ekristen/cast
install ekristen/gcp-nuke
install eksctl-io/eksctl
install fastfetch-cli/fastfetch
install filosottile/age
install fluxcd/flux2
install gitlab/gitlab-org/gitlab-runner
install gitlab/gitlab-org/release-cli
install go-gitea/gitea
install gohugoio/hugo
install golangci/golangci-lint
install google/go-containerregistry
install goreleaser/goreleaser
install go-task/task
install gptscript-ai/clio
install gptscript-ai/gptscript
install hashicorp/packer
install hashicorp/terraform
install helm/helm
install homebrew/p7zip
install imsnif/bandwhich
install instrumenta/kubeval
install istio/istio
install jesseduffield/lazygit
install k3d-io/k3d
install kubernetes/kubectl
install kubernetes-sigs/kind
install ollama/ollama
install open-policy-agent/conftest
install otto8-ai/otto8
install pulumi/pulumi
install sans-sroc/file_exporter
install sans-sroc/odin-utils
install sigstore/cosign
install superfly/flyctl
install thanos-io/thanos
install tursodatabase/turso-cli
install wasmerio/wasmer
EOF

COPY --chmod=755 <<"EOF" /root/dist.sh
#!/bin/bash
export DISTILLERY_CONFIG=/etc/distillery.yaml
export DISTILLERY_NO_SIGNATURE_VERIFY=true
export DISTILLERY_NO_CHECKSUM_VERIFY=true
export DISTILLERY_GITHUB_TOKEN=$(</run/secrets/github-token)
dist run --parallel 10
EOF

RUN --mount=type=secret,id=github-token /root/dist.sh

RUN apt install -y vim git iproute2 ssh make uidmap iptables python3 python3-pip python3-venv python3-requests jq unzip xz-utils
RUN curl -LsSf https://nodejs.org/dist/v22.13.1/node-v22.13.1-linux-$(uname -m | sed 's/aarch/arm/' | sed 's/x86_/x/').tar.xz -o node.tar.xz && \
    tar xvf node.tar.xz  --strip-components=1 -C /usr/local --no-same-owner && \
    rm -f node.tar.xz
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip
RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-$(uname -m | sed 's/aarch64/arm/').tar.gz && \
    tar -xf google-cloud-cli-linux-*.tar.gz && \
    rm google-cloud-cli-linux-*.tar.gz && \
    mv ./google-cloud-sdk /usr/local && \
    /usr/local/google-cloud-sdk/install.sh && \
    echo source /usr/local/google-cloud-sdk/path.bash.inc >> /etc/bash.bashrc && \
    cp /usr/local/google-cloud-sdk/completion.bash.inc /etc/bash_completion.d/
RUN userdel ubuntu && \
    rm -rf /home/ubuntu && \
    useradd -m -s /bin/bash -u 1000 otto8
RUN mkdir -p /home/linuxbrew/.linuxbrew && \
    chown -R otto8:otto8 /home/linuxbrew/.linuxbrew
RUN if [ "$(uname -m)" = "x86_64" ]; then su - otto8 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
    rm -rf /home/otto8/.cache && \
    mv /home/linuxbrew/.linuxbrew/Homebrew /usr/local/share && \
    ln -s /usr/local/share/Homebrew /home/linuxbrew/.linuxbrew; fi
RUN echo 'export PATH=/home/otto8/.distillery/bin:/home/linuxbrew/.linuxbrew/bin:$PATH' >> /etc/bash.bashrc
RUN echo '[ -e /home/otto8/.no-workspace ] || ln -sf /workspace /home/otto8' >> /etc/bash.bashrc
RUN mkdir /mnt/data && chown -R otto8:otto8 /mnt/data && ln -s /mnt/data /workspace && ln -s /mnt/data /home/otto8/workspace
RUN rm -rf /root/.cache /var/lib/apt/lists /var/cache/dist /etc/distillery.yaml /root/Distfile /root/dist.sh

FROM scratch
COPY --link --from=base / /
ENV PATH=/home/linuxbrew/.linuxbrew/bin:/home/otto8/.distillery/bin:$PATH
WORKDIR /workspace
USER 1000
CMD ["/bin/bash"]
