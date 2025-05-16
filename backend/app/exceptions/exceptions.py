from fastapi import HTTPException, status

CREDENTIALS_EXCEPTION = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="Could not validate credentials",
    headers={"WWW-Authenticate": "Bearer"},
)

EMAIL_ALREADY_EXISTS = HTTPException(
    status_code=status.HTTP_400_BAD_REQUEST,
    detail="Email already registered",
)
