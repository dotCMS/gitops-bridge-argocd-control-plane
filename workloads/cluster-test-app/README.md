# 🚀 Simple Cluster Test Application

A **simple, general-purpose test application** for validating Kubernetes cluster functionality. This app provides basic cluster health checks and serves as a test workload for various cluster features.

## Purpose

- ✅ **Cluster Validation**: Verify that deployments, services, and networking work
- 🔗 **Service Mesh Ready**: Linkerd injection enabled (but not required)
- 🌐 **Web Interface**: Simple dashboard showing cluster information
- 📊 **Health Checks**: Basic liveness and readiness probes
- 🎯 **Lightweight**: Minimal resource requirements

## Features

### 🏥 **Health Monitoring**
- HTTP health checks for Kubernetes probes
- Visual status indicators on the web dashboard
- Basic connectivity testing

### 🔗 **Service Mesh Integration**
- **Linkerd injection enabled** by default (via annotation)
- Automatic mTLS encryption when Linkerd is deployed
- No Linkerd-specific complexity - works with or without service mesh

### 📱 **Web Dashboard**
- **Responsive design** with modern UI
- **Cluster information** display (environment, region, cluster name)  
- **Interactive test buttons** for basic functionality checks
- **Service mesh status** indicator

## Deployment

### **Automatic via ArgoCD**
This app is deployed automatically via the **ArgoCD Application** defined in `bootstrap/workloads.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cluster-test-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/dotCMS/gitops-bridge-argocd-control-plane
    path: workloads/cluster-test-app
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: test-apps
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### **Manual Deployment**
```bash
# Deploy using Helm directly
helm install cluster-test-app ./workloads/cluster-test-app \
  --create-namespace \
  --namespace test-apps \
  --set environment=dev \
  --set region=us-west-2 \
  --set cluster_name=my-cluster
```

## Accessing the Application

### **Port Forward Method**
```bash
kubectl port-forward -n test-apps svc/cluster-test-app 8080:80
open http://localhost:8080
```

### **NodePort Method (Optional)**
```bash
# Enable NodePort in values.yaml
nodePort:
  enabled: true
  port: 30080

# Access via cluster IP
curl http://<cluster-node-ip>:30080
```

## Configuration

### **Basic Settings**
```yaml
# values.yaml
replicaCount: 2          # Number of pod replicas
environment: dev         # Environment label
region: us-west-2       # AWS region

# Service configuration
service:
  type: ClusterIP        # Service type
  port: 80              # Service port

# Resource limits
resources:
  limits:
    cpu: 200m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 64Mi
```

### **Linkerd Integration**
```yaml
# Enable/disable Linkerd sidecar injection
linkerd:
  inject: true  # Set to false to disable service mesh
```

## Testing

### **Basic Health Check**
```bash
# Test pod health
kubectl get pods -n test-apps

# Test service
kubectl get svc -n test-apps

# Check logs
kubectl logs -n test-apps deployment/cluster-test-app
```

### **Service Mesh Verification** (if Linkerd enabled)
```bash
# Check Linkerd injection
kubectl get pods -n test-apps -o jsonpath='{.items[*].spec.containers[*].name}' | grep linkerd

# View Linkerd stats
linkerd viz -n test-apps stat deploy

# Check mTLS status
linkerd viz -n test-apps edges deploy
```

### **Network Testing**
```bash
# Test from another pod
kubectl run test-pod --image=curlimages/curl -it --rm -- \
  curl http://cluster-test-app.test-apps.svc.cluster.local
```

## Troubleshooting

### **Common Issues**

**1. Pod not starting:**
```bash
kubectl describe pod -n test-apps <pod-name>
kubectl logs -n test-apps <pod-name>
```

**2. Service not accessible:**
```bash
kubectl get endpoints -n test-apps cluster-test-app
kubectl describe svc -n test-apps cluster-test-app
```

**3. Linkerd injection not working:**
```bash
# Check namespace annotation
kubectl get namespace test-apps -o yaml | grep linkerd

# Verify Linkerd is installed
linkerd check
```

## Use Cases

### **Development**
- Quick cluster functionality validation
- Testing new cluster configurations
- Verifying ingress and service mesh setup

### **Production**  
- Basic cluster health monitoring
- Canary deployments testing
- Network connectivity validation

### **CI/CD**
- Automated cluster testing
- Deployment verification
- Health check endpoint for monitoring

## Architecture

```
┌─────────────────┐
│   LoadBalancer/ │
│   Ingress       │
└─────┬───────────┘
      │
┌─────▼───────────┐
│   Service       │
│   (ClusterIP)   │
└─────┬───────────┘
      │
┌─────▼───────────┐    ┌─────────────┐
│   Deployment    │    │  ConfigMap  │
│   (nginx)       │◄───┤  (HTML)     │
│   replicas: 2   │    └─────────────┘
└─────────────────┘
      │
      ▼
┌─────────────────┐
│  Linkerd Proxy  │ (Optional)
│   (mTLS)        │
└─────────────────┘
```

This simple test app provides a **reliable foundation** for cluster validation without unnecessary complexity! 🎯

