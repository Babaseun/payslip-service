from flask import Blueprint, request, jsonify
from app.payslips.services import upload_payslip_service, list_payslips_service

payslip_bp = Blueprint("payslips", __name__, url_prefix="/payslips")


@payslip_bp.route("/", methods=["POST"])
def upload_payslip():
    try:
        payslip = upload_payslip_service(
            file=request.files.get("file"),
            employee_id=request.form.get("employee_id"),
            month=request.form.get("month"),
            year=request.form.get("year"),
        )
        return (
            jsonify(
                {
                    "message": "Payslip uploaded",
                    "filename": payslip.filename,
                    "payslip_id": payslip.id,
                    "timestamp": payslip.timestamp.isoformat(),
                }
            ),
            201,
        )

    except ValueError as e:
        return jsonify({"error": str(e)}), 400


@payslip_bp.route("/", methods=["GET"])
def list_payslips():
    payslips = list_payslips_service()
    return jsonify({"payslips": [p.serialize() for p in payslips]}), 200
