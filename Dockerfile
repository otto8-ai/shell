FROM ubuntu:24.04 AS base
RUN apt update && \
    apt install -y curl
COPY <<"EOF" /etc/distillery.yaml
path: /usr/local/share/dist
bin_path: /usr/local/bin
# Doesn't work yet
#cache_path: /var/cache/dist
EOF

RUN --mount=type=secret,id=github-token \
    curl --proto '=https' --tlsv1.2 -LsSf https://get.dist.sh | \
    DISTILLERY_CONFIG=/etc/distillery.yaml \
    DISTILLERY_GITHUB_TOKEN=$(</run/secrets/github-token) sh && \
    dist -v

COPY --chmod=755 <<"EOF" /root/dist.sh
#!/bin/bash
export DISTILLERY_CONFIG=/etc/distillery.yaml
export DISTILLERY_NO_SIGNATURE_VERIFY=true
export DISTILLERY_GITHUB_TOKEN=$(</run/secrets/github-token)
dist "$@"
EOF

RUN --mount=type=secret,id=github-token /root/dist.sh install aquasecurity/trivy
RUN --mount=type=secret,id=github-token /root/dist.sh install astral-sh/uv
RUN --mount=type=secret,id=github-token /root/dist.sh install caddyserver/caddy
RUN --mount=type=secret,id=github-token /root/dist.sh install cli/cli
RUN --mount=type=secret,id=github-token /root/dist.sh install coroot/coroot
RUN --mount=type=secret,id=github-token /root/dist.sh install derailed/k9s
RUN --mount=type=secret,id=github-token /root/dist.sh install digitalocean/doctl
RUN --mount=type=secret,id=github-token /root/dist.sh install docker/compose
RUN --mount=type=secret,id=github-token /root/dist.sh install eksctl-io/eksctl
RUN --mount=type=secret,id=github-token /root/dist.sh install filosottile/age
RUN --mount=type=secret,id=github-token /root/dist.sh install fluxcd/flux2
RUN --mount=type=secret,id=github-token /root/dist.sh install golangci/golangci-lint
RUN --mount=type=secret,id=github-token /root/dist.sh install google/go-containerregistry
RUN --mount=type=secret,id=github-token /root/dist.sh install go-task/task
RUN --mount=type=secret,id=github-token /root/dist.sh install gptscript-ai/clio
RUN --mount=type=secret,id=github-token /root/dist.sh install gptscript-ai/gptscript
RUN --mount=type=secret,id=github-token /root/dist.sh install hashicorp/packer
RUN --mount=type=secret,id=github-token /root/dist.sh install hashicorp/terraform
RUN --mount=type=secret,id=github-token /root/dist.sh install helm/helm
RUN --mount=type=secret,id=github-token /root/dist.sh install homebrew/p7zip
RUN --mount=type=secret,id=github-token /root/dist.sh install istio/istio
RUN --mount=type=secret,id=github-token /root/dist.sh install jesseduffield/lazygit
RUN --mount=type=secret,id=github-token /root/dist.sh install k3d-io/k3d
RUN --mount=type=secret,id=github-token /root/dist.sh install kubernetes/kubectl
RUN --mount=type=secret,id=github-token /root/dist.sh install kubernetes-sigs/kind
RUN --mount=type=secret,id=github-token /root/dist.sh install pulumi/pulumi
RUN --mount=type=secret,id=github-token /root/dist.sh install sigstore/cosign
RUN --mount=type=secret,id=github-token /root/dist.sh install superfly/flyctl
RUN --mount=type=secret,id=github-token /root/dist.sh install tursodatabase/turso-cli
RUN --mount=type=secret,id=github-token /root/dist.sh install wasmerio/wasmer
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
RUN echo 'export PATH=/home/linuxbrew/.linuxbrew/bin:$PATH' >> /etc/bash.bashrc
RUN echo '[ -e /home/otto8/.no-workspace ] || ln -sf /workspace /home/otto8' >> /etc/bash.bashrc
RUN mkdir /mnt/data && chown -R otto8:otto8 /mnt/data && ln -s /mnt/data /workspace && ln -s /mnt/data /home/otto8/workspace
RUN rm -rf /root/.cache \
    /var/lib/apt/lists

FROM scratch
COPY --link --from=base / /
ENV PATH=/home/linuxbrew/.linuxbrew/bin:/home/otto8/.distillery/bin:$PATH
WORKDIR /workspace
USER 1000
CMD ["/bin/bash"]
