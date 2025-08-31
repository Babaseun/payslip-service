import pytest
from unittest.mock import patch, MagicMock
from io import BytesIO  
from datetime import datetime  

class TestRoutes:
    
    def test_upload_payslip_success(self, client):
        """Test successful payslip upload via API."""
        with patch('app.payslips.routes.upload_payslip_service') as mock_service:
            # Mock service response
            mock_payslip = MagicMock()
            mock_payslip.filename = "test.pdf"
            mock_payslip.id = 1
            mock_payslip.timestamp.isoformat.return_value = "2023-12-01T10:00:00"  
            mock_service.return_value = mock_payslip
            
            # Create test data
            data = {
                'file': (BytesIO(b'test content'), 'test.pdf'),
                'employee_id': '123',
                'month': '12',
                'year': '2023'
            }
            
            response = client.post('/payslips/', data=data, content_type='multipart/form-data')
            
            assert response.status_code == 201
            assert response.json['message'] == 'Payslip uploaded'
            assert response.json['filename'] == 'test.pdf'
            assert response.json['payslip_id'] == 1
    
    def test_upload_payslip_missing_fields(self, client):
        """Test upload with missing required fields."""
        # Missing employee_id
        data = {
            'file': (BytesIO(b'test content'), 'test.pdf'),
            'month': '12',
            'year': '2023'
        }
        
        response = client.post('/payslips/', data=data, content_type='multipart/form-data')
        assert response.status_code == 400
        assert response.json['error'] == 'Missing required fields'
    
    def test_upload_payslip_service_error(self, client):
        """Test upload when service raises an error."""
        with patch('app.payslips.routes.upload_payslip_service') as mock_service:
            mock_service.side_effect = ValueError("Invalid file type")
            
            data = {
                'file': (BytesIO(b'test content'), 'test.pdf'),
                'employee_id': '123',
                'month': '12',
                'year': '2023'
            }
            
            response = client.post('/payslips/', data=data, content_type='multipart/form-data')
            
            assert response.status_code == 400
            assert response.json['error'] == 'Invalid file type'
    
    def test_list_payslips_empty(self, client):
        """Test listing payslips when none exist."""
        with patch('app.payslips.routes.list_payslips_service') as mock_service:
            mock_service.return_value = []
            
            response = client.get('/payslips/')
            
            assert response.status_code == 200
            assert response.json['payslips'] == []
    
    def test_list_payslips_with_data(self, client):
        """Test listing payslips when data exists."""
        with patch('app.payslips.routes.list_payslips_service') as mock_service:
            # Create mock payslips
            mock_payslip1 = MagicMock()
            mock_payslip1.serialize.return_value = {
                'id': 1,
                'employee_id': '123',
                'month': 12,
                'year': 2023,
                'filename': 'test1.pdf'
            }
            
            mock_payslip2 = MagicMock()
            mock_payslip2.serialize.return_value = {
                'id': 2,
                'employee_id': '456',
                'month': 1,
                'year': 2024,
                'filename': 'test2.pdf'
            }
            
            mock_service.return_value = [mock_payslip1, mock_payslip2]
            
            response = client.get('/payslips/')
            
            assert response.status_code == 200
            assert len(response.json['payslips']) == 2
            assert response.json['payslips'][0]['employee_id'] == '123'
            assert response.json['payslips'][1]['employee_id'] == '456'