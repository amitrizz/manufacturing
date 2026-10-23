/**
 * Multi-tenancy extraction middleware for Manufacturing ERP.
 * Extracts company ID from header, query param, or request body.
 */
export function extractTenant(req) {
  const companyId =
    req.headers['x-company-id'] ||
    req.headers['x-tenant-id'] ||
    req.query.company_id ||
    req.query.companyId ||
    req.body?.company_id ||
    null;
  return companyId ? String(companyId).trim() : null;
}

export function tenantMiddleware(req, res, next) {
  req.companyId = extractTenant(req);
  next();
}
