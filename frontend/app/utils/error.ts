export interface APIError {
  message: string;
  details?: string;
  status?: number;
}

export function handleAPIError(error: unknown): string {
  if (typeof error === 'string') {
    return error;
  }

  if (error instanceof Error) {
    return error.message;
  }

  const apiError = error as APIError;
  if (apiError.message) {
    return apiError.details ? `${apiError.message}: ${apiError.details}` : apiError.message;
  }

  return 'An unexpected error occurred. Please try again.';
}

export function isNetworkError(error: unknown): boolean {
  if (error instanceof Error) {
    return (
      error.message.includes('Network Error') ||
      error.message.includes('Failed to fetch') ||
      error.message.includes('network request failed')
    );
  }
  return false;
}

export function formatErrorMessage(error: unknown): { title: string; message: string } {
  const errorMessage = handleAPIError(error);

  if (isNetworkError(error)) {
    return {
      title: 'Network Error',
      message: 'Please check your internet connection and try again.',
    };
  }

  const apiError = error as APIError;
  if (apiError.status === 401) {
    return {
      title: 'Authentication Error',
      message: 'Please log in again to continue.',
    };
  }

  if (apiError.status === 403) {
    return {
      title: 'Access Denied',
      message: 'You do not have permission to perform this action.',
    };
  }

  if (apiError.status === 404) {
    return {
      title: 'Not Found',
      message: 'The requested resource was not found.',
    };
  }

  if (apiError.status === 422) {
    return {
      title: 'Validation Error',
      message: errorMessage,
    };
  }

  if (apiError.status) {
    if (apiError.status >= 500) {
      return {
        title: 'Server Error',
        message: 'An unexpected server error occurred. Please try again later.',
      };
    }
  }

  return {
    title: 'Error',
    message: errorMessage,
  };
}