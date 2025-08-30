from datetime import datetime
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()


class Payslip(db.Model):
    __tablename__ = "payslips"

    id = db.Column(db.Integer, primary_key=True)
    employee_id = db.Column(db.String(64), nullable=False)
    month = db.Column(db.Integer, nullable=False)
    year = db.Column(db.Integer, nullable=False)
    filename = db.Column(db.String(256), nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    def serialize(self):
        return {
            "id": self.id,
            "employee_id": self.employee_id,
            "month": self.month,
            "year": self.year,
            "filename": self.filename,
            "timestamp": self.timestamp.isoformat(),
        }
