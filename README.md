# nextflow_aks_example

The `nextflow.tf` Terraform file successfully creates an AKS cluster, Azure file storage resource and connects to the storage via a Kubernetes persistent volume.

Nextflow fails when attempting to run a pipeline however:
```
 ✘  ~/workspace/nextflow_k8s  nextflow kuberun nextflow-io/rnatoy -v workflow-volume-claim:/mnt/
Pod started: awesome-miescher
N E X T F L O W  ~  version 20.10.0
Pulling nextflow-io/rnatoy ...
/mnt/projects/nextflow-io/rnatoy/.git/HEAD.lock.817a79c4894e4b35a82c2dd8176b0fa6 -> /mnt/projects/nextflow-io/rnatoy/.git/HEAD.lock: Not supported
```

Attempting to run the same repo a second time gives the following result:
```
 ✘  ~/workspace/nextflow_k8s  nextflow kuberun nextflow-io/rnatoy -v workflow-volume-claim:/mnt/
Pod started: tender-tuckerman
N E X T F L O W  ~  version 20.10.0
Can't find git repository config file -- Repository may be corrupted: /mnt/projects/nextflow-io/rnatoy
```

I'm assuming this has something to do with the configuration of the Azure storage. However, when inspecting the file share, it seems the filesystem structure and contents are correct.
