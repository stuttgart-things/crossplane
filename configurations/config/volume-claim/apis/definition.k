__xrd_group = "resources.stuttgart-things.com"
__xrd_kind = "VolumeClaim"
__xrd_version = "v1alpha1"
__xrd_scope = "Namespaced"
__xrd_plural = "volumeclaims"
__xrd_singular = "volumeclaim"

"""
VolumeClaim Composite Resource Definition
Provides a generic PersistentVolumeClaim abstraction that works with any storage backend.
"""

# ------------------------------------------------------------
# Spec
# ------------------------------------------------------------

# @xrd
schema VolumeClaim:
    # Name of the ProviderConfig to use for the Kubernetes provider
    providerConfigRef: str
    # Name of the PersistentVolumeClaim
    pvcName: str
    # Namespace where the PVC will be created
    namespace?: str = "default"
    # Storage class name to use for provisioning
    storageClassName: str
    # Storage size (e.g., 10Gi, 100Gi, 1Ti)
    storage?: str = "10Gi"
    # Access modes for the PVC (ReadWriteOnce, ReadOnlyMany, ReadWriteMany)
    accessModes?: [str] = ["ReadWriteOnce"]
    # Volume mode (Filesystem or Block)
    volumeMode?: str = "Filesystem"
    # Custom annotations to add to the PVC (e.g., for Harvester: harvesterhci.io/imageId)
    annotations?: {str:str} = {}
    # Custom labels to add to the PVC
    labels?: {str:str} = {}
    # Label selector for binding to pre-provisioned PersistentVolumes
    selector?: LabelSelector
    # Data source for PVC cloning or restoration from snapshots
    dataSource?: DataSource

# ------------------------------------------------------------
# Nested Schemas
# ------------------------------------------------------------

schema LabelSelector:
    # Labels that must exactly match
    matchLabels?: {str:str} = {}
    # Label selector expressions
    matchExpressions?: [MatchExpression] = []

schema MatchExpression:
    # Label key to match against
    key?: str
    # Match operator (In, NotIn, Exists, DoesNotExist)
    operator?: str
    # Values to match (used with In and NotIn operators)
    values?: [str] = []

schema DataSource:
    # Name of the data source (PVC, VolumeSnapshot, etc.)
    name?: str
    # Kind of the data source (e.g., PersistentVolumeClaim, VolumeSnapshot)
    kind?: str
    # API group of the data source (empty for core resources)
    apiGroup?: str

# ------------------------------------------------------------
# Status
# ------------------------------------------------------------

# @status
schema VolumeClaimStatus:
    # Name of the created PersistentVolumeClaim
    pvcName?: str = ""
    # Indicates whether the PVC is ready and bound
    ready?: bool = False