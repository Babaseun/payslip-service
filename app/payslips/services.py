import boto3, uuid
from flask import current_app
from app.models.payslip import Payslip, db

ALLOWED_EXTENSIONS = {"pdf"}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB


def allowed_file(filename):
    if not filename:
       return False
    return (
        "." in filename and
        filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS
    )
   
    

def get_s3_client():
    return boto3.client(
        "s3",
        aws_access_key_id=current_app.config["S3_KEY"],
        aws_secret_access_key=current_app.config["S3_SECRET"],
        region_name=current_app.config["S3_REGION"]
    )

def upload_payslip_service(file, employee_id, month, year):
    
    if not file or not file.filename:
        raise ValueError("No file provided")
    if not allowed_file(file.filename):
        raise ValueError("Only PDF files are allowed")
    if not all([employee_id, month, year]):
        raise ValueError("Missing metadata")

    # Check file size
    file.seek(0, 2)
    file_size = file.tell()
    file.seek(0)
    if file_size > MAX_FILE_SIZE:
        raise ValueError("File size exceeds 10MB limit")

    ext = file.filename.rsplit(".", 1)[1].lower()
    unique_filename = f"{uuid.uuid4().hex}.{ext}"
    s3 = get_s3_client()
    
    try:
        s3.upload_fileobj(
            file,
            current_app.config["S3_BUCKET"],
            unique_filename,
            ExtraArgs={"ACL": "private", "ContentType": file.content_type},
        )
        
        payslip = Payslip(
            employee_id=employee_id,
            month=int(month),
            year=int(year),
            filename=unique_filename,
        )
        db.session.add(payslip)
        db.session.commit()
        return payslip
        
    except Exception as e:
        db.session.rollback()
        raise ValueError(f"Upload failed: {str(e)}")

def list_payslips_service():
    return Payslip.query.all()