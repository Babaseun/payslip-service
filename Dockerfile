FROM python:3.11-slim

WORKDIR /src

# Install curl
RUN apt-get update && apt-get install -y curl --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*


RUN pip install --no-cache-dir pipenv


COPY Pipfile Pipfile.lock ./

RUN pipenv install --system --deploy --ignore-pipfile

COPY run.py ./
COPY app ./app

EXPOSE 5000

# Run the Flask app
CMD ["python", "run.py"]