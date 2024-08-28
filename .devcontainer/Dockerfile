FROM mcr.microsoft.com/devcontainers/base:bookworm

RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
RUN wget -O- https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor | tee /usr/share/keyrings/kubernetes-apt-keyring.gpg
RUN echo 'deb [signed-by=/usr/share/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
RUN wget -O- https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list


# Install Terraform / Direnv / PreCommit / Age / Kubectl / helm / flux
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    terraform \
    direnv \
    pre-commit \
    age \
    kubectl \
    helm \
    && rm -rf /var/lib/apt/lists/* \
    && curl -s https://fluxcd.io/install.sh | bash

# Install SOPS
RUN SOPS_LATEST_VERSION=$(curl -s "https://api.github.com/repos/getsops/sops/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+'); curl -Lo /tmp/sops.deb "https://github.com/getsops/sops/releases/download/v${SOPS_LATEST_VERSION}/sops_${SOPS_LATEST_VERSION}_amd64.deb"; apt --fix-broken install /tmp/sops.deb; rm -rf /tmp/sops.deb

# Install Task
RUN sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin


USER vscode

# Set up direnv hook
RUN echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
RUN echo 'eval "$(direnv hook bash)"' >> ~/.bash_profile

# Copy direnv config
COPY direnv/config.toml /home/vscode/.config/direnv/config.toml

# Enable git
RUN git config --global --add safe.directory /workspaces/homelab
