export const companySchemas = {
  companies: {
    bsonType: 'object',
    required: ['code', 'name'],
    properties: {
      id: { bsonType: 'string', description: 'Unique identifier' },
      code: { bsonType: 'string', description: 'Unique company short code' },
      name: { bsonType: 'string', description: 'Legal company name' },
      gst_number: { bsonType: ['string', 'null'] },
      phone: { bsonType: ['string', 'null'] },
      email: { bsonType: ['string', 'null'] },
      address: { bsonType: ['string', 'null'] },
      currency: { bsonType: 'string' },
      fiscal_year_start: { bsonType: ['string', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  company_roles: {
    bsonType: 'object',
    required: ['code', 'name'],
    properties: {
      id: { bsonType: 'string' },
      code: { bsonType: 'string' },
      name: { bsonType: 'string' },
      description: { bsonType: ['string', 'null'] },
      permissions: { bsonType: ['array', 'string', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },
};
