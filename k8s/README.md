# Scalable Backend with Kubernetes on AWS

A CRUD REST API (Posts) deployed on AWS EKS with MongoDB Replica Set, HPA, and Ingress.

## Architecture

- **Backend**: Node.js + Express (CRUD API)
- **Database**: MongoDB 7 deployed as a 3-node Replica Set using StatefulSet
- **Orchestration**: Kubernetes on AWS EKS
- **Infrastructure**: Terraform (VPC, EKS, ECR modules)
- **Scaling**: Horizontal Pod Autoscaler (HPA) — scales from 1 to 5 pods at 70% CPU

## API Endpoints

| Method | Endpoint      | Description       |
|--------|---------------|-------------------|
| GET    | /posts        | Get all posts     |
| GET    | /posts/:id    | Get post by ID    |
| POST   | /posts        | Create a post     |
| PUT    | /posts/:id    | Update a post     |
| DELETE | /posts/:id    | Delete a post     |

## Setup Steps

### 1. Prerequisites
```bash
- AWS CLI configured
- kubectl installed
- Terraform >= 1.0
- Docker installed
```

### 2. Provision Infrastructure
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform apply
```

### 3. Configure kubectl
```bash
aws eks update-kubeconfig --name k8s-crud-cluster --region us-east-1
```

### 4. Build and Push Docker Image
```bash
docker build -t yourusername/posts-api:latest ./app
docker push yourusername/posts-api:latest
```

### 5. Deploy to Kubernetes
```bash
kubectl apply -f k8s/backend/namespace.yaml
kubectl apply -f k8s/mongodb/
kubectl apply -f k8s/backend/
```

### 6. Install NGINX Ingress Controller
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/aws/deploy.yaml
```

### 7. Get External IP
```bash
kubectl get ingress -n backend
```

### 8. Initialize MongoDB Replica Set (if init container fails)
```bash
kubectl exec -it mongodb-0 -n backend -- mongosh
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongodb-0.mongodb.backend.svc.cluster.local:27017" },
    { _id: 1, host: "mongodb-1.mongodb.backend.svc.cluster.local:27017" },
    { _id: 2, host: "mongodb-2.mongodb.backend.svc.cluster.local:27017" }
  ]
})
```

## Validation

### Test API via Ingress
```bash
INGRESS_IP=$(kubectl get ingress backend-ingress -n backend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://$INGRESS_IP/posts
```

### Test Autoscaling
```bash
# Generate load
kubectl run load-test --image=busybox -n backend --restart=Never -- \
  sh -c "while true; do wget -q -O- http://posts-api-service/posts; done"

# Watch HPA
kubectl get hpa -n backend -w
```

### Test High Availability
```bash
# Delete a backend pod — system keeps running
kubectl delete pod <pod-name> -n backend

# Delete a MongoDB pod — no data loss
kubectl delete pod mongodb-1 -n backend
kubectl exec -it mongodb-0 -n backend -- mongosh --eval "rs.status()"
```