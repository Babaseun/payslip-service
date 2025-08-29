import os
from flask import current_app
from werkzeug.utils import secure_filename
from app.models.payslip import Payslip, db

ALLOWED_EXTENSIONS = {'pdf'}

def allowed_file(filename):
    return filename and '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def upload_payslip_service(file, employee_id, month, year):
    if not file or not file.filename:
        raise ValueError('No file provided')
    if not allowed_file(file.filename):
        raise ValueError('Only PDF files are allowed')
    if not all([employee_id, month, year]):
        raise ValueError('Missing metadata: employee_id, month, or year')

    filename = secure_filename(file.filename)
    upload_dir = current_app.config.get('UPLOAD_FOLDER', 'uploads')
    os.makedirs(upload_dir, exist_ok=True)
    path = os.path.join(upload_dir, filename)
    file.save(path)

    payslip = Payslip(
        employee_id=employee_id,
        month=int(month),
        year=int(year),
        filename=filename
    )
    db.session.add(payslip)
    db.session.commit()
    return payslip

def list_payslips_service():
    return Payslip.query.all()
