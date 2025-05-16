from functools import wraps
import asyncio
import logging
from typing import TypeVar, Callable, Any

T = TypeVar('T')

logger = logging.getLogger(__name__)

class RetryException(Exception):
    pass

def with_retry(
    max_retries: int = 3,
    base_delay: float = 1.0,
    max_delay: float = 10.0,
    exceptions: tuple = (Exception,),
) -> Callable[[Callable[..., T]], Callable[..., T]]:
    """
    Decorator para adicionar retry com exponential backoff em funções assíncronas.
    
    Args:
        max_retries: Número máximo de tentativas
        base_delay: Delay inicial entre tentativas (em segundos)
        max_delay: Delay máximo entre tentativas (em segundos)
        exceptions: Tuple de exceções que devem trigger o retry
    """
    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        @wraps(func)
        async def wrapper(*args: Any, **kwargs: Any) -> T:
            last_exception = None
            
            for attempt in range(max_retries):
                try:
                    return await func(*args, **kwargs)
                except exceptions as e:
                    last_exception = e
                    if attempt == max_retries - 1:
                        logger.error(f"Max retries ({max_retries}) reached for {func.__name__}", exc_info=True)
                        raise RetryException(f"Failed after {max_retries} retries") from e
                    
                    delay = min(base_delay * (2 ** attempt), max_delay)
                    logger.warning(
                        f"Attempt {attempt + 1}/{max_retries} failed for {func.__name__}. "
                        f"Retrying in {delay:.2f}s"
                    )
                    await asyncio.sleep(delay)
            
            if last_exception:
                raise last_exception
            return None  # Type safety
            
        return wrapper
    return decorator