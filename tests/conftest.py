import pytest
import os
from flask import Flask
from unittest.mock import patch, MagicMock
from app import create_app
from app.models.payslip import db as _db

@pytest.fixture(scope='session')
def app():
    """Create application for the tests."""
    # Set test environment variables
    os.environ['DB_CONNECTION'] = 'sqlite:///:memory:'
    os.environ['S3_KEY'] = 'test-key'
    os.environ['S3_SECRET'] = 'test-secret'
    os.environ['S3_REGION'] = 'test-region'
    os.environ['S3_BUCKET'] = 'test-bucket'
    
    # Create app
    app = create_app()
    
    # Ensure testing mode
    app.config['TESTING'] = True
    
    with app.app_context():
        _db.create_all()
        yield app
        _db.drop_all()

@pytest.fixture(scope='function')
def session(app):
    """Create a new database session for each test."""
    # For Flask-SQLAlchemy 3.x, use the session directly
    # and handle transactions manually
    
    # Start a transaction
    connection = _db.engine.connect()
    transaction = connection.begin()
    
    # Bind the session to the connection
    _db.session.begin(nested=True)
    
    yield _db.session
    
    # Rollback the transaction after test
    _db.session.rollback()
    transaction.rollback()
    connection.close()

@pytest.fixture
def client(app):
    """Create test client."""
    return app.test_client()