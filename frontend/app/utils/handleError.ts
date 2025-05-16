interface ErrorWithMessage {
  message: string
}

function isErrorWithMessage(error: unknown): error is ErrorWithMessage {
  return (
    typeof error === 'object' &&
    error !== null &&
    'message' in error &&
    typeof (error as Record<string, unknown>).message === 'string'
  )
}

function toErrorWithMessage(maybeError: unknown): ErrorWithMessage {
  if (isErrorWithMessage(maybeError)) return maybeError

  try {
    return new Error(JSON.stringify(maybeError))
  } catch {
    // fallback in case there's an error stringifying the maybeError
    // like with circular references for example.
    return new Error(String(maybeError))
  }
}

export function getErrorMessage(error: unknown) {
  return toErrorWithMessage(error).message
}

interface ApiErrorResponse {
  error?: {
    message?: string
    details?: string
  }
  message?: string
  detail?: string
}

export async function handleApiError(response: Response): Promise<string> {
  try {
    const data = (await response.json()) as ApiErrorResponse
    return (
      data.error?.message ||
      data.error?.details ||
      data.message ||
      data.detail ||
      response.statusText ||
      'An unexpected error occurred'
    )
  } catch (err) {
    return response.statusText || 'An unexpected error occurred'
  }
}