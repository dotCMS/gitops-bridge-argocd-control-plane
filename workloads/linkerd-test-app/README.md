# 🔗 Linkerd Test Application

This test application demonstrates **Linkerd service mesh** features including **automatic mTLS**, **observability**, and **traffic management**.

## Architecture

```
┌─────────────────┐     mTLS     ┌─────────────────┐
│   Frontend      │ ──────────► │   Backend       │
│   (nginx)       │              │   (httpbin)     │
│   Port: 80      │              │   Port: 8080    │ 
└─────────────────┘              └─────────────────┘
         │                                │
         ▼                                ▼
  ┌─────────────┐                ┌─────────────┐
  │ Linkerd     │                │ Linkerd     │
  │ Proxy       │                │ Proxy       │
  └─────────────┘                └─────────────┘
```

## Features Demonstrated

### 🔒 **Automatic mTLS**
- **Zero-config encryption** between frontend and backend
- **Certificate rotation** handled automatically by Linkerd
- **Policy enforcement** with traffic encryption

### 📊 **Observability**  
- **Real-time metrics** for request success rates, latency, and throughput
- **Distributed tracing** across service calls
- **Traffic visualization** in Linkerd dashboard

### 🚦 **Traffic Management**
- **Load balancing** between multiple backend replicas
- **Circuit breaking** and **retry policies**
- **Traffic splitting** capabilities (configurable)

## Deployment

This application is deployed via **ArgoCD** as part of the GitOps workflow:

```yaml
# Deployed automatically when workloads are enabled
namespace: linkerd-test
replicas:
  frontend: 2
  backend: 2
```

## Testing the Application

### 1. **Access the Frontend**
```bash
# Port forward to access the web UI
kubectl port-forward -n linkerd-test svc/linkerd-test-app-frontend 8080:80

# Open in browser
open http://localhost:8080
```

### 2. **Test Backend Communication**
```bash
# Test frontend -> backend communication
kubectl exec -n linkerd-test deployment/linkerd-test-app-frontend -c nginx -- \
  curl -s http://linkerd-test-app-backend:8080/status

# Test with headers
kubectl exec -n linkerd-test deployment/linkerd-test-app-frontend -c nginx -- \
  curl -s http://linkerd-test-app-backend:8080/headers
```

### 3. **Generate Load Test Traffic**
The application includes an automatic **load test job** that generates traffic between services:

```bash
# Check load test job status
kubectl get jobs -n linkerd-test

# View load test logs
kubectl logs -n linkerd-test job/linkerd-test-app-load-test
```

## Linkerd Observability

### **View Real-time Metrics**
```bash
# Install Linkerd Viz (if not already installed)
linkerd viz install | kubectl apply -f -

# View deployment stats
linkerd viz -n linkerd-test stat deploy

# View live traffic (top command)
linkerd viz -n linkerd-test top deploy

# View service mesh edges
linkerd viz -n linkerd-test edges deploy
```

### **Access Linkerd Dashboard**
```bash
# Open Linkerd web dashboard
linkerd viz dashboard

# Navigate to linkerd-test namespace to see:
# - Request success rates
# - P50, P95, P99 latency metrics  
# - Traffic flow between services
# - mTLS status indicators
```

### **Verify mTLS Encryption**
```bash
# Check TLS status between services
linkerd viz -n linkerd-test edges deploy -o wide

# Should show "🔒" indicating encrypted connections
```

## Configuration

### **Environment-Specific Values**
```yaml
# environments/{env}/workloads/linkerd-test-app/values.yaml
frontend:
  replicaCount: 2  # Adjust per environment

backend:
  replicaCount: 2  # Adjust per environment

loadTest:
  enabled: true    # Enable/disable load testing
  requests: 10     # Number of test requests
```

### **Linkerd Features**
```yaml
linkerd:
  inject: true           # Enable sidecar injection
  trafficSplit:
    enabled: false       # Enable traffic splitting (A/B testing)
```

## Troubleshooting

### **Check Pod Status**
```bash
kubectl get pods -n linkerd-test
kubectl describe pod -n linkerd-test <pod-name>
```

### **Check Linkerd Injection**
```bash
# Verify Linkerd proxy injection
kubectl get pods -n linkerd-test -o jsonpath='{.items[*].spec.containers[*].name}' | tr ' ' '\n' | sort | uniq

# Should include 'linkerd-proxy' containers
```

### **Check Service Communication**
```bash
# Test direct backend connection
kubectl exec -n linkerd-test deployment/linkerd-test-app-frontend -c nginx -- \
  curl -v http://linkerd-test-app-backend:8080/status

# Check proxy stats
kubectl exec -n linkerd-test deployment/linkerd-test-app-frontend -c linkerd-proxy -- \
  curl -s http://127.0.0.1:4191/stats | grep backend
```

### **Common Issues**

**1. Services not communicating:**
- Verify namespace has `linkerd.io/inject: enabled` annotation
- Check pod has `linkerd-proxy` sidecar container
- Verify service selectors match pod labels

**2. mTLS not working:**
- Check Linkerd installation: `linkerd check`
- Verify certificate status: `linkerd identity`
- Check policy configuration if using strict mode

**3. Load test failing:**
- Ensure services are ready before job starts
- Check service DNS resolution
- Verify network policies allow communication

## Metrics and Monitoring

The application provides several metrics endpoints:

- **Frontend Health**: `http://frontend/health`
- **Backend Status**: `http://backend:8080/status`  
- **Backend Headers**: `http://backend:8080/headers`
- **Linkerd Proxy Metrics**: `http://127.0.0.1:4191/stats` (from within pod)

## Next Steps

1. **Enable Traffic Splitting**: Set `trafficSplit.enabled: true` for A/B testing
2. **Add Retries**: Configure retry policies for resilience
3. **Add Circuit Breakers**: Implement failure handling
4. **Enable Policy**: Add Linkerd policy for fine-grained access control
