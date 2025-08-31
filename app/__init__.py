from flask import Flask
from app.models.payslip import db
from app.payslips.routes import payslip_bp
from flask import current_app
import os

def create_app(config=None):
    app = Flask(__name__)
    if config:
        app.config.from_object(config)

    app.config.from_prefixed_env()
    app.config["SQLALCHEMY_DATABASE_URI"] = os.environ.get("DB_CONNECTION", "sqlite:///default.db")
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

    db.init_app(app)
    app.register_blueprint(payslip_bp)

    with app.app_context():
        db.create_all()

    return app
