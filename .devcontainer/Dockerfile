FROM mcr.microsoft.com/devcontainers/base:bookworm@sha256:72aa734731c4332ffe363051212aa036b7cc6808c62580414a4d03b3c7ae1d10

RUN echo "Acquire::http::Pipeline-Depth 0;" > /etc/apt/apt.conf.d/99custom && \
    echo "Acquire::http::No-Cache true;" >> /etc/apt/apt.conf.d/99custom && \
    echo "Acquire::BrokenProxy    true;" >> /etc/apt/apt.conf.d/99custom

RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
RUN wget -O- https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor | tee /usr/share/keyrings/kubernetes-apt-keyring.gpg
RUN echo 'deb [signed-by=/usr/share/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
RUN wget -O- https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list


# Install Terraform / Direnv / PreCommit / Age / Kubectl / helm / flux / yq
RUN apt-get clean && rm -rf /var/lib/apt/lists/* && apt-get update && apt-get install -y \
    wget \
    unzip \
    terraform \
    direnv \
    pre-commit \
    age \
    kubectl \
    helm \
    yq \
    && rm -rf /var/lib/apt/lists/* \
    && curl -s https://fluxcd.io/install.sh | bash

# Install SOPS
RUN SOPS_LATEST_VERSION=$(curl -s "https://api.github.com/repos/getsops/sops/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+'); curl -Lo /tmp/sops.deb "https://github.com/getsops/sops/releases/download/v${SOPS_LATEST_VERSION}/sops_${SOPS_LATEST_VERSION}_amd64.deb"; apt --fix-broken install /tmp/sops.deb; rm -rf /tmp/sops.deb

# Install Task
RUN sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin

# Install Yamlfmt
RUN YAMLFMT_LATEST_VERSION=$(curl -s "https://api.github.com/repos/google/yamlfmt/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+');curl -s -L "https://github.com/google/yamlfmt/releases/download/v${YAMLFMT_LATEST_VERSION}/yamlfmt_${YAMLFMT_LATEST_VERSION}_Linux_x86_64.tar.gz" | tar xvz -C /tmp/ yamlfmt; install /tmp/yamlfmt /usr/local/bin; rm -rf /tmp/yamlfmt

# Install Step-ca
RUN cd /tmp; wget https://dl.smallstep.com/cli/docs-ca-install/latest/step-cli_amd64.deb; sudo dpkg -i step-cli_amd64.deb; rm -rf step-cli_amd64.deb

USER vscode

# Set up direnv hook
RUN echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
RUN echo 'eval "$(direnv hook bash)"' >> ~/.bash_profile

# Copy direnv config
COPY direnv/config.toml /home/vscode/.config/direnv/config.toml

# Enable git
RUN git config --global --add safe.directory /workspaces/homelab
