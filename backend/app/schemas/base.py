from typing import Optional, Any
from pydantic import BaseModel


class SuccessResponse(BaseModel):
    success: bool = True
    message: str = "OK"
    data: Optional[Any] = None


class ErrorResponse(BaseModel):
    success: bool = False
    message: str


class PaginatedResponse(BaseModel):
    success: bool = True
    total: int
    page: int
    page_size: int
    data: list
