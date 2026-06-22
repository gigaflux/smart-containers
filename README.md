# Smart Containerized Environment

This repository contains smart-ready Docker configurations, custom single-architecture images, and automation scripts for running test environments. It isolates environments, manages complex multi-arch system dependencies, and provides a predictable local development setup.

# 🎯 Primary Goal: Local Big Data Development & Testing

The ultimate goal of this project is to provide Data Engineers with a **lightweight, robust, and completely isolated local sandbox for developing and testing complex Big Data pipelines**.
Instead of wasting cloud budget or waiting for slow CI/CD cycles, developers can run, debug, and validate their Apache Spark jobs locally on their laptops with full production parity.

---

## 🛠️ Architecture and Stack

* **Core**: Apache Airflow[Celery]
* **Database**: PostgreSQL (Metadata Storage)
* **Broker**: Redis (For Celery Executor queue management)
* **Containers**: Docker / Docker Compose / OCI-compliant builds
* **Providers**: Apache Spark / GreenPlum / ClickHouse

---

## 💻 Local Quickstart

### Prerequisites
* Docker Desktop 4.x+ or Docker Engine 24.x+
* GNU Make 3.81+
* OpenSSL (for certificate generation)

### 1. Initialize Environment
Clone the repository and run the initialization command. This script automatically generates internal cluster passwords, cryptographic keys, and secure SSL/TLS certificates, saving them to a local git-ignored vault.
```bash
git clone https://github.com/gigaflux/smart-containers.git
cd smart-containers
# Generate passwords, SSL certs, and populate the local vault in .var/vault directory
make init
```

---

### 2. Run the Cluster
Pulls the corresponding pre-built images and spins up the multi-container environment.
```bash
# Pull correct architecture image from GHCR and start all Airflow services
make up
```

---

*Airflow Webserver will be available at:* **`http://localhost:8080`**  
*Default Credentials:* 
* **Username**: `dev`
* **Password**: Stored securely inside **`./var/.vault/airflow-api/airflow-api.pwd`** (generated automatically during the `make init` phase).

---

## 📁 Repository Structure

```text
├── src/
│   └── airflow/
│       ├── airflow-core/         # ApiServer/Scheduler/DagProcessor
│       ├── airflow-db/           # Metadata Database layer (PostgreSQL)
│       ├── airflow-redis/        # Celery Broker layer (Redis)
│       ├── airflow-worker/       # Airflow Worker/Triggerer
│       ├── docker-compose.yaml   # Multi-container orchestration manifests
│       ├── init.sh               # Generate passwords, SSL certs
│       ├── Makefile              # Aiflow makefile
│       └── ...
├── var/                          # Local state and generated runtime data (Git-ignored)
│   └── .vault/                   # Secure storage for cryptographic keys and secrets
│       └── airflow-api/
│           └── airflow-api.pwd   # Auto-generated secure password for 'dev' user
├── Makefile                      # Root orchestration workflow entrypoint
└── README.md                     # Project documentation
```

---

## 🤝 Contributing
Welcome! Feel free to open an issue or submit a pull request if you want to improve this local big data sandbox.

