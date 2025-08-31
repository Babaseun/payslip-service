# Payslip Microservice

## A backend microservice that handles employee payslip uploads.

## 🔧 Tech Stack

- **Flask** – Python web framework for API development
- **Docker** – Containerization of the app
- **AWS ECR** – Hosting and deployment of Docker images
- **Pipenv** – Python dependency management
- **AWS S3** – Object storage of uploaded pdf files
- **Pytest** – Unit testing framework

---

## Project Structure

```

├── app
│   ├── __init__.py
│   ├── models
│   └── payslips
├── Dockerfile
├── infrastructure
│   └── terraform
├── Pipfile
├── Pipfile.lock
├── README.md
├── run.py
└── tests
    ├── __init__.py
    ├── conftest.py
    └── test_payslips

```

## 📋 Requirements

- [Python 3.13+](https://www.python.org/downloads/)
- [Pipenv](https://pipenv.pypa.io/en/latest/)
- [Docker](https://www.docker.com/)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) (for ECR login & push)

---

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/Babaseun/payslip-service
cd payslip-service
```

2. Build and start the API:

   ```
    python3 run.py

    The server will be listening on port 5000
   ```

3. To run test unit tests:

   ```
   pipenv run pytest
   ```

### Endpoints

1. Upload employee payslips:

   - URL: `POST /payslips`
   - Description: To upload payslips (PDF), including Employee ID, month, year, filename, timestamp.

1. Get employee payslips:

   - URL: `GET /payslips`
   - Description: Endpoint to retrieve all uploaded payslips.
