# Task Manager

Ths is a small full-stack app for keeping track of personal tasks. It has a Spring Boot API, a React web client, and an optional Flutter mobile client. All three clients use the same JWT-authenticated  backend.

## What it can do

- Register and sign in with email and password.
- Keep each user's tasks isolated from every other account.
- Show useful validation and API errors in the web interface.
- Create, edit, complete, filter, search, and delete tasks.
- Run locally with an in-memory H2 database or with MySQL in Docker.
- Use the same API from the included Flutter client.

## Requirements

For local development you will need JDK 21 or newer, Maven 3.8 or newer,
Node.js 18 or newer, and npm. MySQL 8 is only needed for the production-style
profile. Flutter is required only if you want to run the mobile client.

## Run it locally

### Start the backend with H2

This is the quickest way to get the app running. It does not require MySQL.

```bash
cd backend
mvn spring-boot:run -Dspring-boot.run.profiles=h2
```

The API will be available at `http://localhost:8080`. The H2 profile seeds a
demo account:

```text
Email:    demo@example.com
Password: password123
```

### Start the web app

Open a second terminal:

```bash
cd frontend
npm install
npm run build
npm run dev
```

Then open `http://localhost:5173`. Vite proxies `/api` requests to the backend
on port 8080. `npm run typecheck` checks TypeScript, while `npm run build`
checks and bundles the production app.

### Run the Flutter app

```bash
cd mobile
flutter pub get
flutter run
```

On an Android emulator, the default API address is `http://10.0.2.2:8080`.
Override it with `--dart-define=API_BASE_URL=http://your-host:8080`.

## Run with Docker Compose

Docker Compose starts MySQL, the backend, and nginx serving the frontend:

```bash
docker compose up --build
```

Once the containers are ready, open `http://localhost`. The API is also
available at `http://localhost:8080`. MySQL data is stored in the `db_data`
Docker volume, so it survives container restarts.

The Compose file contains development credentials and a sample JWT secret.
Replace them before using this setup anywhere beyond local development.

## API overview

The API base URL is `http://localhost:8080/api`.

### Authentication

| Method | Endpoint | Body |
| --- | --- | --- |
| `POST` | `/auth/register` | `{ "email", "fullName", "password" }` |
| `POST` | `/auth/login` | `{ "email", "password" }` |

Successful authentication returns a JWT. Send it with task requests as:

```http
Authorization: Bearer <token>
```

### Tasks

| Method | Endpoint | Purpose |
| --- | --- | --- |
| `GET` | `/tasks` | List the signed-in user's tasks |
| `GET` | `/tasks/{id}` | Read one task |
| `POST` | `/tasks` | Create a task |
| `PUT` | `/tasks/{id}` | Update a task |
| `DELETE` | `/tasks/{id}` | Delete a task |

`GET /tasks` accepts optional `status` and `search` query parameters. Search
matches task titles and descriptions. Task ownership is checked in the service
layer, so knowing another user's task ID is not enough to access it.

Validation failures use a structured response similar to this:

```json
{
  "timestamp": "2026-09-19T12:00:00Z",
  "status": 400,
  "error": "Bad Request",
  "message": "Title is required",
  "path": "/api/tasks",
  "fieldErrors": {
    "title": "Title is required"
  }
}
```

## Tests and CI

Run the backend tests with:

```bash
cd backend
mvn test
```

The frontend build also performs a TypeScript check:

```bash
cd frontend
npm run build
```

The `Jenkinsfile` at the repository root defines the pipeline. It runs backend
verification (`mvn verify`) and the frontend build in parallel, then creates the
ECR repositories if needed and pushes both Docker images on `main`. Deployment
is off by default and runs only when the `DEPLOY` parameter is enabled on `main`;
it copies `docker-compose.prod.yml` to an EC2 host and restarts the stack with
the images that were just pushed. Set `USE_BUNDLED_DB` to also ship
`docker-compose.db.yml`, which runs MySQL on the host instead of using RDS.

Create a Pipeline or Multibranch Pipeline job pointing at this repository, and
make sure the agent provides JDK 21, Maven, Node 20, npm, Docker, and the AWS
CLI with an IAM role that can push to ECR. The target EC2 instance needs an IAM
role that can pull from ECR. Store the SSH key plus `DB_URL`, `DB_USERNAME`,
`DB_PASSWORD`, and `JWT_SECRET` as Jenkins credentials before deploying.

## Configuration and security

The backend reads database and JWT settings from environment variables in the
production profile, including `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, and
`JWT_SECRET`. The H2 profile is intended for local development and does not
need MySQL settings.

Before deploying, use a strong `JWT_SECRET`, change the default database
credentials, and configure the frontend nginx API target for the deployed
backend URL.

## Infrastructure (Terraform)

The `terraform/` directory provisions the AWS side of this setup: a VPC with
public subnets for the app host and private subnets for RDS, two ECR
repositories, the Jenkins and EC2 IAM roles and instance profiles, an EC2
application host with an Elastic IP, and optionally an RDS MySQL instance.

State is stored in S3 with native lockfile locking. Create the bucket once using
the bootstrap configuration, then point the main configuration at it:

```bash
cd terraform/bootstrap
terraform init && terraform apply   # copy the backend_config output

cd ..
cp backend.hcl.example backend.hcl   # fill in the bucket and region from the output
cp terraform.tfvars.example terraform.tfvars   # set allowed_ssh_cidrs and db_password
terraform init -backend-config=backend.hcl
terraform apply
```

SSH (port 22) is closed unless `allowed_ssh_cidrs` is set. The app host's IAM
role includes SSM Session Manager as an alternative; the Jenkins pipeline still
deploys over SSH, so set `allowed_ssh_cidrs` to the Jenkins agent's public IP.

Set `create_rds = true` to provision RDS in the private subnets. The outputs
include the EC2 public IP (use it as the Jenkins `EC2_HOST` parameter), the ECR
repository URLs, the `database_url` for the `taskmanager-db-url` credential, and
the Jenkins instance profile to attach to the Jenkins host. The bundled MySQL
container is only used when `USE_BUNDLED_DB` is enabled; otherwise `DB_URL` must
point at an external database such as RDS.
