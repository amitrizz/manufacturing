export const unitSchemas = {
  units: {
    bsonType: 'object',
    required: ['code', 'name', 'symbol'],
    properties: {
      id: { bsonType: 'string', description: 'Unique unit ID' },
      code: { bsonType: 'string', description: 'Uppercase unit identifier e.g. KG, PCS, M' },
      name: { bsonType: 'string', description: 'Full descriptive unit name e.g. Kilogram' },
      symbol: { bsonType: 'string', description: 'Standard abbreviation/symbol e.g. kg, pcs, m' },
      category: {
        enum: ['Weight', 'Volume', 'Count', 'Packaging', 'Length', 'Area', 'Other'],
        bsonType: 'string',
      },
      precision: { bsonType: 'number', description: 'Decimal precision for quantities' },
      is_active: { bsonType: ['boolean', 'number'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },
};
