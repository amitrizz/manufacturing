export const inventorySchemas = {
  materials: {
    bsonType: 'object',
    required: ['code', 'name', 'unit', 'current_stock'],
    properties: {
      id: { bsonType: 'string' },
      code: { bsonType: 'string' },
      name: { bsonType: 'string' },
      category: { bsonType: 'string' },
      unit: { bsonType: 'string' },
      current_stock: { bsonType: 'number' },
      minimum_stock: { bsonType: 'number' },
      maximum_stock: { bsonType: 'number' },
      unit_cost: { bsonType: ['number', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  product_categories: {
    bsonType: 'object',
    required: ['code', 'name'],
    properties: {
      id: { bsonType: 'string' },
      code: { bsonType: 'string' },
      name: { bsonType: 'string' },
      created_at: { bsonType: 'number' },
    },
  },

  products: {
    bsonType: 'object',
    required: ['code', 'name', 'unit'],
    properties: {
      id: { bsonType: 'string' },
      code: { bsonType: 'string' },
      name: { bsonType: 'string' },
      category_id: { bsonType: ['string', 'null'] },
      unit: { bsonType: 'string' },
      description: { bsonType: ['string', 'null'] },
      standard_rate: { bsonType: ['number', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  bom: {
    bsonType: 'object',
    required: ['product_id', 'version'],
    properties: {
      id: { bsonType: 'string' },
      product_id: { bsonType: 'string' },
      version: { bsonType: 'string' },
      is_active: { bsonType: ['number', 'boolean', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  bom_items: {
    bsonType: 'object',
    required: ['bom_id', 'material_id', 'quantity'],
    properties: {
      id: { bsonType: 'string' },
      bom_id: { bsonType: 'string' },
      material_id: { bsonType: 'string' },
      quantity: { bsonType: 'number' },
      unit: { bsonType: 'string' },
    },
  },
};
