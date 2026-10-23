/**
 * Formal MongoDB Collection Schemas for Manufacturing ERP
 * Aggregated from domain schema modules.
 */
import { companySchemas } from './company.schema.js';
import { staffSchemas } from './staff.schema.js';
import { plantSchemas } from './plant.schema.js';
import { unitSchemas } from './unit.schema.js';
import { inventorySchemas } from './inventory.schema.js';
import { productionSchemas } from './production.schema.js';
import { qualitySchemas } from './quality.schema.js';
import { maintenanceSchemas } from './maintenance.schema.js';
import { dispatchSchemas } from './dispatch.schema.js';
import { purchaseSchemas } from './purchase.schema.js';
import { auditSchemas } from './audit.schema.js';

export const MongoSchemas = {
  ...companySchemas,
  ...staffSchemas,
  ...plantSchemas,
  ...unitSchemas,
  ...inventorySchemas,
  ...productionSchemas,
  ...qualitySchemas,
  ...maintenanceSchemas,
  ...dispatchSchemas,
  ...purchaseSchemas,
  ...auditSchemas,
};

export const ALL_COLLECTIONS = Object.keys(MongoSchemas);

export {
  companySchemas,
  staffSchemas,
  plantSchemas,
  unitSchemas,
  inventorySchemas,
  productionSchemas,
  qualitySchemas,
  maintenanceSchemas,
  dispatchSchemas,
  purchaseSchemas,
  auditSchemas,
};
