# 🔐 Linkerd Certificate Management Guide

This document explains how certificate management works in our Linkerd deployment and provides options for different security requirements.

## Current Setup Overview

Our Linkerd addon supports **two certificate management approaches**:

### 1. **Built-in Certificate Management** (Current Default)
```yaml
identity:
  issuer:
    scheme: kubernetes.io/tls
```

**✅ Advantages:**
- Simple setup, no external dependencies
- Automatic certificate rotation
- Works out-of-the-box

**⚠️ Limitations:**
- Self-signed certificates only
- No integration with organizational PKI
- Limited certificate lifecycle management

### 2. **cert-manager Integration** (Production Recommended)
```yaml
certManager:
  enabled: true
  trustAnchor: "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----"
```

**✅ Advantages:**
- Integration with organizational PKI
- ACME/Let's Encrypt support for public certificates
- Advanced certificate lifecycle management
- External CA validation
- Compliance with enterprise certificate policies

---

## Configuration Options by Environment

### **Development Environment**
```yaml
# Dev uses built-in certificates for simplicity
identity:
  issuer:
    scheme: kubernetes.io/tls

certManager:
  enabled: false
```

### **Production Environment**
```yaml
# Production uses cert-manager with organizational CA
identity:
  issuer:
    scheme: linkerd.io/tls
    clockSkewAllowance: 20s
    issuanceLifetime: 24h0m0s

certManager:
  enabled: true
  trustAnchor: |
    -----BEGIN CERTIFICATE-----
    # Your organization's root CA certificate
    -----END CERTIFICATE-----
```

---

## How to Enable cert-manager Integration

### Step 1: Enable cert-manager in your environment
```yaml
# In environments/{env}/addons/linkerd/values.yaml
certManager:
  enabled: true
  trustAnchor: |
    -----BEGIN CERTIFICATE-----
    # Your organization's root CA goes here
    MIIFazCCA1OgAwIBAgIRAIIQz7DSQONZRGPgu2OCiwAwDQYJKoZIhvcNAQELBQAw
    # ... rest of your root CA certificate
    -----END CERTIFICATE-----
  trustAnchorKey: |
    -----BEGIN PRIVATE KEY-----
    # Your organization's root CA private key
    # This should be stored securely (e.g., in AWS Secrets Manager)
    -----END PRIVATE KEY-----
```

### Step 2: Update identity configuration
```yaml
identity:
  issuer:
    scheme: linkerd.io/tls  # Use cert-manager issuer
    clockSkewAllowance: 20s
    issuanceLifetime: 24h0m0s
```

### Step 3: Deploy and verify
```bash
# Check cert-manager certificates
kubectl get certificates -n linkerd

# Verify Linkerd identity
linkerd check --proxy
```

---

## Security Considerations

### **Root CA Management**
- **Development**: Built-in Linkerd CA is acceptable
- **Production**: Use your organization's PKI root CA
- **Storage**: Store root CA private key in AWS Secrets Manager or similar

### **Certificate Rotation**
- **Built-in**: Automatic rotation by Linkerd (90 days default)
- **cert-manager**: Configurable rotation (48h default, renewed at 25h)

### **Network Policies**
Linkerd certificates enable **automatic mTLS** between services:
```yaml
# Services are automatically secured with mTLS
apiVersion: v1
kind: Service
metadata:
  annotations:
    linkerd.io/inject: enabled  # ← Automatic mTLS
```

---

## Troubleshooting

### Check Certificate Status
```bash
# Linkerd certificate check
linkerd check --proxy

# cert-manager certificate status
kubectl get certificates -n linkerd
kubectl describe certificate linkerd-identity-issuer -n linkerd
```

### Common Issues

**1. Certificate Validation Failures**
```bash
# Check trust anchor
kubectl get secret linkerd-identity-trust-anchor -n linkerd -o yaml

# Verify certificate chain
linkerd identity --context=ext-secrets-mc-dev
```

**2. cert-manager Integration Issues**
```bash
# Check ClusterIssuer status
kubectl get clusterissuer linkerd-identity-issuer -o yaml

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager
```

---

## Recommendations

### **For Development Environments**
- Use built-in Linkerd certificate management
- Focus on functionality over security
- Enable debug features for troubleshooting

### **For Production Environments**
- Enable cert-manager integration
- Use organizational root CA
- Store certificates in AWS Secrets Manager
- Enable strict network policies (`defaultPolicy: "deny"`)
- Monitor certificate expiration

### **For Compliance Requirements**
- Integrate with organizational PKI
- Use Hardware Security Modules (HSMs) for CA keys
- Enable audit logging for all certificate operations
- Implement certificate lifecycle automation

