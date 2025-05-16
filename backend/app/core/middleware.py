from fastapi import Request, HTTPException, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from app.utils.retry import RetryException
from app.core.responses import ErrorResponse, ValidationErrorResponse, ValidationErrorDetail
from typing import List
import logging

logger = logging.getLogger(__name__)

async def error_handler(request: Request, call_next):
    try:
        return await call_next(request)
    except HTTPException:
        # Repropaga HTTPException para ser tratado pelo FastAPI
        raise
    except Exception as exc:
        logger.error(f"Unhandled error: {str(exc)}", exc_info=True)
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content=ErrorResponse(
                code="INTERNAL_ERROR",
                message="An unexpected error occurred",
                details={"error": str(exc)} if request.app.debug else None
            ).dict()
        )

async def validation_exception_handler(request: Request, exc: RequestValidationError):
    details: List[ValidationErrorDetail] = []
    
    for error in exc.errors():
        field = ".".join(str(loc) for loc in error["loc"] if loc != "body")
        details.append(
            ValidationErrorDetail(
                field=field,
                message=error["msg"]
            )
        )
    
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content=ValidationErrorResponse(details=details).dict()
    )

async def retry_exception_handler(request: Request, exc: RetryException):
    return JSONResponse(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        content=ErrorResponse(
            code="SERVICE_UNAVAILABLE",
            message="The service is temporarily unavailable",
            details={"error": str(exc)}
        ).dict()
    )