export class HttpError extends Error {
  constructor(status, code, message, details = undefined) {
    super(message);
    this.name = 'HttpError';
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

export function isHttpError(error) {
  return error instanceof HttpError;
}

export function asHttpError(error) {
  if (isHttpError(error)) {
    return error;
  }

  return new HttpError(500, 'internal_error', 'An unexpected service error occurred.');
}
