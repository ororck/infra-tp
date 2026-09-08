resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "10.8.2"

  depends_on = [azurerm_kubernetes_cluster.aks]
}

resource "kubernetes_manifest" "app_bdd" {
  manifest = yamldecode(file("${path.module}/argocd-application.yaml"))

  depends_on = [helm_release.argocd]
}
