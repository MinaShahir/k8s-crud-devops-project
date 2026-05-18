Scalable Backend with Kubernetes on AWS (EKS)A production-style, cloud-native CRUD REST API deployed on Amazon Elastic Kubernetes Service (EKS). This project features a highly available MongoDB 7 Replica Set, automated horizontal pod autoscaling, Ingress traffic routing, and Infrastructure as Code (IaC) provisioned via modularized Terraform.🚀 Project OverviewThis repository demonstrates how to design, provision, and deploy a resilient, auto-scaling backend system using modern DevOps and cloud-native methodologies.The core application is a Node.js & Express CRUD API for managing posts. It is containerized using Docker, managed via Kubernetes orchestration, and built on a highly available infrastructure network on AWS.⚡ Key FeaturesInfrastructure as Code (IaC): Modularized Terraform setups to build entire VPC and EKS clusters dynamically.High Availability: Multiple backend replicas via Kubernetes Deployments alongside automated self-healing pod recovery.Stateful MongoDB Replica Set: 3-node MongoDB cluster using StatefulSets for stable network identities, data redundancy, and automated failovers.Horizontal Autoscaling: Dynamic scaling from 2 to 5 pods driven by CPU utilization metrics.Edge Routing & Ingress: Centralized external traffic management using the NGINX Ingress Controller.Persistent Storage: Block storage configuration ensuring absolute database durability even after pod restarts or nodes shifting.🏗️ Architecture & Tech StackCore Component LayeringBackend API: Node.js, Express.js, MongooseDatabase: MongoDB 7 (3-Node Replica Set: mongodb-0, mongodb-1, mongodb-2)Containerization: DockerOrchestration Platform: Kubernetes (AWS EKS Cluster)Infrastructure Provisioning: Terraform >= 1.0Autoscaling Engine: Horizontal Pod Autoscaler (HPA)Traffic Routing: NGINX Ingress ControllerInfrastructure Architecture FlowPlaintext                    Internet
                        │
                        ▼
              NGINX Ingress Controller
                        │
                        ▼
                Kubernetes Service
                        │
         ┌──────────────┴──────────────┐
         ▼                             ▼
    Backend Pod 1                Backend Pod 2
         │                             │
         └──────────────┬──────────────┘
                        ▼
                 MongoDB Replica Set
          ┌──────────┬──────────┬──────────┐
          ▼          ▼          ▼
      mongodb-0  mongodb-1  mongodb-2
📂 Project StructureBash.
├── app/
│   ├── Dockerfile
│   ├── package.json
│   └── server.js
│
├── k8s/
│   ├── backend/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── ingress.yaml
│   │   ├── hpa.yaml
│   │   └── namespace.yaml
│   │
│   └── mongodb/
│       ├── configmap.yaml
│       ├── secret.yaml
│       ├── service.yaml
│       └── statefulset.yaml
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── versions.tf
│   │
│   └── modules/
│       ├── vpc/
│       ├── eks/
│       ├── ecr/
│       ├── iam/
│       └── security-groups/
│
└── README.md
🔥 API EndpointsPost ManagementMethodEndpointDescriptionRequest Body (JSON)GET/postsGet all postsNoneGET/posts/:idGet single post by IDNonePOST/postsCreate a new post{"title": "Hello", "content": "My first post"}PUT/posts/:idUpdate an existing post{"title": "Updated Title", "content": "Updated content"}DELETE/posts/:idDelete a post by IDNone⚙️ Deployment Workflow1. PrerequisitesEnsure you have the following CLI utilities installed and configured on your machine:AWS CLI (configured with valid access keys)kubectlTerraform (>= 1.0)Docker Desktop / Engine2. Clone the Repository & Configure AWSBashgit clone https://github.com/MinaShahir/k8s-crud-devops-project.git
cd k8s-crud-devops-project

# Configure your AWS CLI access context
aws configure
# Enter: Access Key, Secret Key, and Region (Default: us-east-1)
3. Provision Infrastructure via TerraformTerraform dynamically provisions your AWS networking and cluster platform layer including: VPC, Public/Private Subnets, Internet/NAT Gateways, Security Groups, EKS Cluster + Node Groups, and an ECR Repository.Bashcd terraform
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your custom contextual values if needed
terraform init
terraform apply
4. Configure Cluster Authentication ContextUpdate your local kubeconfig to safely point to your freshly minted EKS cluster:Bashaws eks update-kubeconfig --region us-east-1 --name k8s-crud-cluster

# Verify your worker node connectivity state
kubectl get nodes
5. Install Core Platform ExtensionsYou must deploy the metrics-server extension to allow the HPA engine to read live resource metrics, alongside an Ingress controller for routing.Bash# Install Kubernetes Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Install NGINX Ingress Controller for AWS
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

# Verify Controller Startup
kubectl get pods -n ingress-nginx
6. Build and Push Application ImageBashcd ../app

# Build and tag your application container
docker build -t minashahir/posts-api:v1 .

# Authenticate and Push image to your container registry registry
docker login
docker push minashahir/posts-api:v1
7. Deploy Applications to KubernetesBashcd ..
# Instantiate namespace context and spin up MongoDB stateful engines
kubectl apply -f k8s/backend/namespace.yaml
kubectl apply -f k8s/mongodb/

# Verify MongoDB cluster pods step up
kubectl get pods -n backend

# Deploy backend configurations, deployment strategies, services, and HPA targets
kubectl apply -f k8s/backend/
8. Initialize MongoDB Replica Set (Fallback Step)If your database pods do not automatically bootstrap through an init-container, execute into the main replica pod and pass configuration variables manually:Bashkubectl exec -it mongodb-0 -n backend -- mongosh
JavaScriptrs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongodb-0.mongodb.backend.svc.cluster.local:27017" },
    { _id: 1, host: "mongodb-1.mongodb.backend.svc.cluster.local:27017" },
    { _id: 2, host: "mongodb-2.mongodb.backend.svc.cluster.local:27017" }
  ]
})
📈 System Validation & TestingAccessing the API via IngressTo fetch your AWS network dynamic load balancer endpoint, query your ingress component parameters:Bashkubectl get ingress -n backend

# Or save it to a variable for automated testing
INGRESS_IP=$(kubectl get ingress backend-ingress -n backend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://$INGRESS_IP/posts
Autoscaling Validation (HPA)The app is configured to dynamically scale based on the following configurations:Minimum Replicas: 2 podsMaximum Replicas: 5 podsCPU Threshold Target: 70%Run a temporary test pod container executing infinite looped queries to stress cluster workloads:Bashkubectl run load-generator -i --tty --rm --image=busybox --restart=Never -- /bin/sh

# Once inside the container shell, hit the cluster internal service endpoint:
while true; do wget -q -O- http://posts-api-service.backend.svc.cluster.local/posts; done
Open a separate split terminal window context to actively watch the automatic step scaling parameters:Bashkubectl get hpa -n backend -w
Resiliency & Failover TestsBackend Self-Healing: Terminate an operational application API pod instance. Kubernetes should quickly instantiate an alternate replacement pod to match replication conditions without dropping availability.Bashkubectl delete pod <backend-pod-name> -n backend
Stateful Database Resilience: Remove an active member of your database architecture to track stateful disk volume attachments and replication election loops.Bash# Insert or review a post document first, then run:
kubectl delete pod mongodb-1 -n backend

# Check health and verification flags inside remaining nodes
kubectl exec -it mongodb-0 -n backend -- mongosh --eval "rs.status()"
🔧 TroubleshootingHPA Metrics Showing <unknown> Target Metrics:This typically means the Metrics Server is not installed or hasn't finished initial scraping loops. Ensure you run:Bashkubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
EKS Authentication Errors (kubectl commands failing):Refresh your current cluster terminal authentication context profiles:Bashaws eks update-kubeconfig --region us-east-1 --name k8s-crud-cluster
Ingress Routing or External Target Issues:Confirm that the ingress routing container controllers are fully provisioned and have successfully bound to an external AWS Application Load Balancer endpoint:Bashkubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
🚀 Future Enhancements Roadmap[ ] Implement automated CI/CD pipeline structures using GitHub Actions.[ ] Introduce declarative GitOps deployment models with Argo CD.[ ] Configure real-time cloud observability metrics using Prometheus and Grafana dashboards.[ ] Package application deployments into reusable Helm Charts.[ ] Restructure directories to support multi-environment configurations (Dev / Staging / Production).[ ] Offload configuration passwords securely by integrating AWS Secrets Manager.[ ] Enforce HTTPS traffic routing with automatic TLS certificates generation.🧼 Teardown and CleanupTo completely delete and wind down all provisioned cloud resources to prevent ongoing billing on AWS, run the following commands:Bashcd terraform
terraform destroy
👨‍💻 AuthorMina ShahirGitHub Profile: https://github.com/MinaShahir