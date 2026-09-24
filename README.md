🐳 Dockerized Microservices — URL Shortener

A hands-on Docker and Microservices project built to understand how multiple containerized services communicate, share networks, persist data, and work together using Docker Compose.

The project implements a simple URL Shortener with separate services for URL management and analytics, backed by PostgreSQL.

---

🏗️ Architecture

                         ┌──────────────┐
                         │   Browser    │
                         └──────┬───────┘
                                │
                                │ HTTP :5000
                                ▼
                       ┌──────────────────┐
                       │   URL Service    │
                       │   Node + Express │
                       └────────┬─────────┘
                                │
                    ┌───────────┴───────────┐
                    │                       │
                    │                       │
                    ▼                       ▼
          ┌──────────────────┐    ┌──────────────────┐
          │    Analytics     │    │    PostgreSQL    │
          │     Service      │    │     Database     │
          │   Node + Express │    │                  │
          └──────────────────┘    └────────┬─────────┘
                                           │
                                           ▼
                                    ┌──────────────┐
                                    │  db-data     │
                                    │ Docker Volume│
                                    └──────────────┘

              All services communicate through
                 a Docker Compose network

---

🚀 Features

- Create shortened URLs
- Retrieve the original URL using a short ID
- Track URL access/clicks
- Separate URL and Analytics services
- PostgreSQL for persistent URL storage
- Dockerized services
- Container-to-container communication
- Docker Compose orchestration
- Docker networking and service discovery
- Persistent PostgreSQL storage using Docker volumes
- PostgreSQL health checks
- Environment-based configuration

---

🛠️ Tech Stack

Technology| Purpose
Node.js| Runtime
Express.js| Backend APIs
PostgreSQL| Persistent database
Docker| Containerization
Docker Compose| Multi-container orchestration
Docker Network| Service-to-service communication
Docker Volumes| Persistent database storage

---

📁 Project Structure

docker-microservices/  
│  
├── url-service/  
│   ├── Dockerfile  
│   ├── package.json  
│   ├── package-lock.json  
│   └── server.js  
│
├── analytics-service/  
│   ├── Dockerfile  
│   ├── package.json  
│   ├── package-lock.json  
│   └── server.js  
│  
└── compose.yaml  

---

🐳 Docker Architecture

The project uses three containers:

URL Service

Responsible for:

- Creating short URLs
- Retrieving original URLs
- Communicating with PostgreSQL
- Sending click events to the Analytics Service

url-service  
     │  
     ├── PostgreSQL  
     │  
     └── Analytics Service  

Analytics Service

Responsible for:

- Receiving click events
- Tracking URL access counts
- Providing analytics for each short URL

PostgreSQL

Responsible for:

- Persisting shortened URLs
- Storing original URLs
- Maintaining data even when the database container is recreated

---

🌐 Docker Networking

All services communicate through a Docker network created by Docker Compose.

                Docker Network
                     │
        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
   URL Service   Analytics    PostgreSQL
                  Service

Docker's internal DNS allows services to communicate using their service names instead of container IP addresses.

For example:

URL Service  
     │  
     │ http://analytics-service:6000  
     ▼  
Analytics Service  
  
and:  
  
URL Service
     │
     │ db:5432
     ▼
PostgreSQL

No hardcoded container IP addresses are required.

---

💾 Persistent Storage

PostgreSQL uses a Docker volume:

volumes:
  - db-data:/var/lib/postgresql/data

This separates the database data from the PostgreSQL container itself.

PostgreSQL Container  
        │  
        ▼  
   db-data Volume  
        │  
        ▼  
    Database Data  

Therefore, deleting and recreating the PostgreSQL container does not delete the stored URLs.

---  

❤️ Health Checks

PostgreSQL includes a Docker health check using "pg_isready".

healthcheck:
  test: ["CMD-SHELL", "pg_isready -U taskuser -d taskdb"]
  interval: 5s
  timeout: 5s
  retries: 5

The URL service waits for PostgreSQL to become healthy before starting.

PostgreSQL starts  
       ↓  
Health check  
       ↓  
Healthy?  
   │       │
  No      Yes
   │       │
 Wait      ▼
       URL Service

---

⚙️ Environment Configuration

The URL service receives its database configuration through environment variables:

environment:
  DB_HOST: db
  DB_PORT: 5432
  DB_USER: taskuser
  DB_PASSWORD: taskpassword
  DB_NAME: taskdb

The important part is:

DB_HOST=db

"db" is the PostgreSQL service name defined in "compose.yaml".

---

▶️ Running the Project

Prerequisites

Make sure you have:

- Docker
- Docker Compose

installed on your machine.

Verify:

docker --version
docker compose version

---

1. Clone the repository

git clone <your-repository-url>
cd docker-microservices

---

2. Build and start the services

docker compose up --build

Or run in detached mode:

docker compose up -d --build

---

3. Check running containers

docker compose ps

You should see:

url-service
analytics-service
db

---

4. Check logs

View all logs:

docker compose logs

View a specific service:

docker compose logs url-service

docker compose logs analytics-service

docker compose logs db

Follow logs in real time:

docker compose logs -f

---

🔌 API Endpoints

URL Service

Health Check

GET /  

Response:  

{  
  "service": "URL Service",  
  "status": "running"  
}  

---

Create Short URL  

POST /shorten  

Request:  

{  
  "url": "https://github.com"  
}  

Example response:  

{  
  "shortId": "abc123",  
  "url": "https://github.com"  
}  

---  

Get Original URL  

GET /url/:id  

Example:  

GET /url/abc123  

Response:  

{  
  "url": "https://github.com"  
}  

Accessing the URL also sends a click event to the Analytics Service.  

---  

Analytics Service  

Health Check  

GET /  

Response:  

{  
  "service": "Analytics Service",  
  "status": "running"  
}  

---  

Track Click  

POST /track  

Request:  

{  
  "shortId": "abc123"  
}  

---  

Get Statistics  

GET /stats/:shortId  

Example:  

GET /stats/abc123  

Response:  

{  
  "shortId": "abc123",  
  "clicks": 5  
}  

---

🧪 Example Flow

Create a shortened URL:

POST /shorten  
       │  
       ▼  
  URL Service  
       │  
       ▼  
  PostgreSQL  
       │  
       ▼  
  Short URL Created  

When the short URL is accessed:  

GET /url/abc123  
       │  
       ▼  
  URL Service  
       │
       ├──────────────► PostgreSQL  
       │                     │  
       │                     ▼  
       │                Original URL  
       │
       └──────────────► Analytics Service  
                              │  
                              ▼  
                         Click Count +1  

---

🧠 Docker Concepts Practiced

This project was built primarily to understand Docker, rather than simply to build a URL shortener.

Docker Fundamentals

- Docker Images
- Docker Containers
- Dockerfiles
- Docker build context
- Image layers
- Docker layer caching
- Port mapping
- Environment variables

Docker Storage

- Docker Volumes
- Persistent database storage
- Container lifecycle vs persistent data

Docker Networking

- User-defined Docker networks
- Container-to-container communication
- Docker DNS
- Service-name based discovery
- Internal vs published ports

Docker Compose

- Multi-container applications
- "compose.yaml"
- Service definitions
- "depends_on"
- Health checks
- Networks
- Volumes
- Building services
- Running multiple services

Docker Debugging

- "docker logs"
- "docker exec"
- "docker inspect"
- "docker network inspect"
- "docker stats"
- Container lifecycle management

---

🎯 Project Goal

The primary goal of this project is to understand how multiple independent applications can run as isolated containers and communicate with each other through Docker networking.

The URL shortener is simply the application used to demonstrate these Docker concepts in a practical environment.

---

📌 Key Takeaways

Dockerfile  
    ↓  
Docker Image  
    ↓  
Docker Container  
    │  
    ├── Network  
    │      └── Service-to-service communication  
    │  
    ├── Volume  
    │      └── Persistent data  
    │  
    └── Environment  
           └── Runtime configuration  

Docker Compose then brings these individual pieces together into a single multi-container application.  

---

📚 Future Improvements

Possible extensions to this project include:

- Redis caching
- Asynchronous event processing
- Message queues
- Authentication
- API Gateway
- Rate limiting
- Better analytics
- Production-ready multi-stage builds
- Container resource management
- Kubernetes deployment
- CI/CD

«These are intentionally kept outside the current scope so the project remains focused on understanding Docker and containerized microservices.»
