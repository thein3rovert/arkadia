# DevOps development environment
# Usage: nix develop .#devops
{
  pkgs,
  inputs ? null,
}:
pkgs.mkShell {
  name = "devops-dev";

  buildInputs = with pkgs; [
    # Container tools
    docker
    docker-compose
    podman
    buildah
    skopeo
    dive # Docker image explorer

    # Kubernetes tools
    kubectl
    kubectx # Includes kubens
    k9s # TUI for Kubernetes
    kubernetes-helm
    helmfile
    kustomize
    stern # Multi-pod log tailing
    kubeseal # Sealed secrets

    # Infrastructure as Code
    terraform
    opentofu # Open-source Terraform fork
    terragrunt
    terraform-docs
    tflint
    infracost # Cost estimates for Terraform

    # Configuration management
    ansible
    ansible-lint

    # CI/CD tools
    github-cli
    gitlab-runner
    act # Run GitHub Actions locally

    # Cloud CLIs
    awscli2
    google-cloud-sdk
    azure-cli
    doctl # DigitalOcean CLI

    # Monitoring and observability
    prometheus
    grafana
    # Note: promtool is included in prometheus package

    # Service mesh
    istioctl
    linkerd

    # Security and secrets
    vault
    sops
    age # Encryption tool
    trivy # Security scanner

    # Scripting and automation
    python3
    jq
    yq-go
    jo # JSON output from shell

    # Network tools
    curl
    wget
    httpie
    netcat
    nmap
    tcpdump
    wireshark-cli

    # System utilities
    htop
    btop
    lsof
    tmux
    git
    gnumake

    # Linters and formatters
    shellcheck
    shfmt
    yamllint
  ];

  # Environment variables
  DOCKER_BUILDKIT = "1";
  COMPOSE_DOCKER_CLI_BUILD = "1";

  shellHook = ''
    echo "🚀 DevOps Development Environment"
    echo ""
    echo "Container tools:"
    echo "  docker / podman           - Container runtime"
    echo "  docker-compose            - Multi-container applications"
    echo "  dive                      - Explore Docker images"
    echo "  buildah / skopeo          - Build and manage containers"
    echo ""
    echo "Kubernetes:"
    echo "  kubectl                   - Kubernetes CLI"
    echo "  k9s                       - Kubernetes TUI"
    echo "  helm                      - Package manager"
    echo "  kubectx / kubens          - Switch contexts/namespaces (kubens included in kubectx)"
    echo "  stern <pod>               - Multi-pod logs"
    echo ""
    echo "Infrastructure as Code:"
    echo "  terraform / opentofu      - Infrastructure provisioning"
    echo "  terragrunt                - Terraform wrapper"
    echo "  ansible                   - Configuration management"
    echo "  tflint                    - Terraform linter"
    echo ""
    echo "Cloud CLIs:"
    echo "  aws                       - AWS CLI"
    echo "  gcloud                    - Google Cloud CLI"
    echo "  az                        - Azure CLI"
    echo "  doctl                     - DigitalOcean CLI"
    echo ""
    echo "Security & Secrets:"
    echo "  vault                     - HashiCorp Vault"
    echo "  sops                      - Secrets management"
    echo "  trivy                     - Security scanner"
    echo "  kubeseal                  - Sealed secrets"
    echo ""
    echo "CI/CD:"
    echo "  gh                        - GitHub CLI"
    echo "  act                       - Run GitHub Actions locally"
    echo "  gitlab-runner             - GitLab CI runner"
    echo ""
    echo "Utilities:"
    echo "  jq / yq                   - JSON/YAML processors"
    echo "  httpie / curl             - HTTP clients"
    echo "  shellcheck                - Shell script linter"
    echo ""
    echo "💡 Tip: Use 'kubectx' and 'kubens' to quickly switch contexts"
    echo ""
  '';
}
