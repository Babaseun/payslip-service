import pytest
from unittest.mock import patch, MagicMock
from app.payslips.services import allowed_file, upload_payslip_service, list_payslips_service
from app.models.payslip import Payslip

class TestServices:
    
    def test_allowed_file_valid_pdf(self):
        assert allowed_file("test.pdf") == True
    
    def test_allowed_file_invalid_extensions(self):
        assert allowed_file("test.txt") == False
    
    @patch('app.payslips.services.current_app')  
    @patch('app.payslips.services.get_s3_client')
    def test_upload_payslip_service_success(self, mock_get_s3_client, mock_current_app, session):
        """Test successful payslip upload."""
        # Mock current_app config
        mock_current_app.config = {
            'S3_KEY': 'test-key',
            'S3_SECRET': 'test-secret',
            'S3_REGION': 'test-region',
            'S3_BUCKET': 'test-bucket'
        }
        
        # Mock S3 client
        mock_s3 = MagicMock()
        mock_get_s3_client.return_value = mock_s3
        
        # Create mock file
        mock_file = MagicMock()
        mock_file.filename = "test.pdf"
        mock_file.content_type = "application/pdf"
        mock_file.seek.return_value = None
        mock_file.tell.return_value = 1024  # 1KB file
        
        # Call service
        payslip = upload_payslip_service(
            file=mock_file,
            employee_id="123",
            month="12",
            year="2023"
        )
        
        # Assertions
        assert payslip.employee_id == "123"
        assert payslip.month == 12
        assert payslip.year == 2023
        assert payslip.filename.endswith(".pdf")
        mock_s3.upload_fileobj.assert_called_once()
    
    def test_upload_payslip_service_no_file(self):
        """Test upload with no file."""
        with pytest.raises(ValueError, match="No file provided"):
            upload_payslip_service(
                file=None,
                employee_id="123",
                month="12",
                year="2023"
            )
    
    def test_upload_payslip_service_invalid_file_type(self):
        """Test upload with invalid file type."""
        mock_file = MagicMock()
        mock_file.filename = "test.txt"
        
        with pytest.raises(ValueError, match="Only PDF files are allowed"):
            upload_payslip_service(
                file=mock_file,
                employee_id="123",
                month="12",
                year="2023"
            )
    
    def test_upload_payslip_service_missing_metadata(self):
        """Test upload with missing metadata."""
        mock_file = MagicMock()
        mock_file.filename = "test.pdf"
        
        with pytest.raises(ValueError, match="Missing metadata"):
            upload_payslip_service(
                file=mock_file,
                employee_id=None,
                month="12",
                year="2023"
            )
    
    def test_upload_payslip_service_file_too_large(self):
        """Test upload with file exceeding size limit."""
        mock_file = MagicMock()
        mock_file.filename = "test.pdf"
        mock_file.content_type = "application/pdf"
        mock_file.seek.return_value = None
        mock_file.tell.return_value = 11 * 1024 * 1024  # 11MB file
        
        with pytest.raises(ValueError, match="File size exceeds 10MB limit"):
            upload_payslip_service(
                file=mock_file,
                employee_id="123",
                month="12",
                year="2023"
            )
    
    @patch('app.payslips.services.current_app')  # This should be first
    @patch('app.payslips.services.get_s3_client')
    def test_upload_payslip_service_s3_failure(self, mock_get_s3_client, mock_current_app, session):
        """Test upload when S3 fails."""
        # Mock current_app config
        mock_current_app.config = {
            'S3_KEY': 'test-key',
            'S3_SECRET': 'test-secret',
            'S3_REGION': 'test-region',
            'S3_BUCKET': 'test-bucket'
        }
        
        # Mock S3 client to raise exception
        mock_s3 = MagicMock()
        mock_s3.upload_fileobj.side_effect = Exception("S3 error")
        mock_get_s3_client.return_value = mock_s3
        
        mock_file = MagicMock()
        mock_file.filename = "test.pdf"
        mock_file.content_type = "application/pdf"
        mock_file.seek.return_value = None
        mock_file.tell.return_value = 1024
        
        with pytest.raises(ValueError, match="Upload failed: S3 error"):
            upload_payslip_service(
                file=mock_file,
                employee_id="123",
                month="12",
                year="2023"
            )
    
    
    def test_list_payslips_service_with_data(self, session):
            """Test listing payslips when data exists."""
            # First, clear any existing data
            session.query(Payslip).delete()
            session.commit()
            
            # Create test payslips
            payslip1 = Payslip(
                employee_id="123",
                month=12,
                year=2023,
                filename="test1.pdf"
            )
            payslip2 = Payslip(
                employee_id="456",
                month=1,
                year=2024,
                filename="test2.pdf"
            )
            
            session.add(payslip1)
            session.add(payslip2)
            session.commit()
            
            payslips = list_payslips_service()
            assert len(payslips) == 2
            
            # Check specific properties to ensure we have the right data
            employee_ids = [p.employee_id for p in payslips]
            assert "123" in employee_ids
            assert "456" in employee_ids