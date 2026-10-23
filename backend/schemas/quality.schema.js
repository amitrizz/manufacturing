export const qualitySchemas = {
  quality_inspections: {
    bsonType: 'object',
    required: ['inspection_number', 'production_order_id', 'status'],
    properties: {
      id: { bsonType: 'string' },
      inspection_number: { bsonType: 'string' },
      production_order_id: { bsonType: 'string' },
      inspector_id: { bsonType: ['string', 'null'] },
      quantity: { bsonType: 'number' },
      sample_size: { bsonType: ['number', 'null'] },
      rejected_quantity: { bsonType: 'number' },
      result: { enum: ['PASS', 'FAIL', 'REWORK', 'PARTIAL_PASS', null], bsonType: ['string', 'null'] },
      status: { enum: ['PENDING', 'COMPLETED', 'CANCELLED'], bsonType: 'string' },
      remarks: { bsonType: ['string', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  quality_results: {
    bsonType: 'object',
    required: ['inspection_id', 'parameter', 'result'],
    properties: {
      id: { bsonType: 'string' },
      inspection_id: { bsonType: 'string' },
      parameter: { bsonType: 'string' },
      expected_value: { bsonType: ['string', 'null'] },
      actual_value: { bsonType: ['string', 'null'] },
      result: { enum: ['PASS', 'FAIL'], bsonType: 'string' },
      remarks: { bsonType: ['string', 'null'] },
      created_at: { bsonType: 'number' },
    },
  },

  rework_orders: {
    bsonType: 'object',
    required: ['rework_number', 'inspection_id', 'quantity'],
    properties: {
      id: { bsonType: 'string' },
      rework_number: { bsonType: 'string' },
      inspection_id: { bsonType: 'string' },
      quantity: { bsonType: 'number' },
      status: { enum: ['PENDING', 'IN_PROGRESS', 'RESOLVED', 'SCRAPPED'], bsonType: 'string' },
      notes: { bsonType: ['string', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },
};
