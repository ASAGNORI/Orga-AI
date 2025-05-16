from typing import Optional, Any, Dict, List
from pydantic import BaseModel

class ErrorResponse(BaseModel):
    code: str
    message: str
    details: Optional[Dict[str, Any]] = None

class SuccessResponse(BaseModel):
    data: Any
    meta: Optional[Dict[str, Any]] = None

class PaginatedResponse(BaseModel):
    data: List[Any]
    meta: Dict[str, Any] = {
        "current_page": 1,
        "per_page": 10,
        "total": 0,
        "total_pages": 1
    }

class ValidationErrorDetail(BaseModel):
    field: str
    message: str

class ValidationErrorResponse(BaseModel):
    code: str = "VALIDATION_ERROR"
    message: str = "Validation error"
    details: List[ValidationErrorDetail]