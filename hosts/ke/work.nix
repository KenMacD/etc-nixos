{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    (azure-cli.withExtensions (with pkgs.azure-cli-extensions; [graphservices]))
    checkov # Static code analysis tool for infrastructure-as-code
    drawio
    freerdp3
    granted
    jira-cli-go
    postman
    proxychains-ng
    slirp4netns
    terraformer
    terragrunt
    tfsec # Terraform static analysis tool
    trivy # Container security scanner

    # K8 clients
    k9s
    kdash
    lens
    seabird
  ];
}
