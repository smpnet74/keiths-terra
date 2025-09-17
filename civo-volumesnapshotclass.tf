# Create a VolumeSnapshotClass for Civo CSI driver
# This enables volume snapshots for database backups and other storage needs

# Create VolumeSnapshotClass using kubectl
resource "null_resource" "civo_volumesnapshotclass" {
  depends_on = [time_sleep.wait_for_cluster, null_resource.csi_snapshot_crds]

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = "${path.module}/kubeconfig"
    }
    command = <<-EOT
      cat <<EOF | kubectl apply -f -
      apiVersion: snapshot.storage.k8s.io/v1
      kind: VolumeSnapshotClass
      metadata:
        name: civo-snapshot-class
        annotations:
          snapshot.storage.kubernetes.io/is-default-class: "true"
      driver: csi.civo.com
      deletionPolicy: Delete
      EOF
    EOT
  }
}