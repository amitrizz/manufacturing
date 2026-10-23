export const plantSchemas = {
  factories: {
    bsonType: 'object',
    required: ['code', 'name'],
    properties: {
      id: { bsonType: 'string' },
      code: { bsonType: 'string' },
      name: { bsonType: 'string' },
      location: { bsonType: ['string', 'null'] },
      created_at: { bsonType: 'number' },
    },
  },

  production_lines: {
    bsonType: 'object',
    required: ['code', 'name', 'factory_id'],
    properties: {
      id: { bsonType: 'string' },
      factory_id: { bsonType: 'string' },
      code: { bsonType: 'string' },
      name: { bsonType: 'string' },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  machines: {
    bsonType: 'object',
    required: ['code', 'name', 'line_id', 'status'],
    properties: {
      id: { bsonType: 'string' },
      code: { bsonType: 'string' },
      name: { bsonType: 'string' },
      machine_type: { bsonType: ['string', 'null'] },
      line_id: { bsonType: 'string' },
      status: { enum: ['RUNNING', 'IDLE', 'BREAKDOWN', 'MAINTENANCE', 'OFFLINE', 'STOPPED'], bsonType: 'string' },
      current_product_id: { bsonType: ['string', 'null'] },
      current_operator: { bsonType: ['string', 'null'] },
      efficiency: { bsonType: 'number' },
      runtime_seconds: { bsonType: 'number' },
      downtime_seconds: { bsonType: 'number' },
      last_maintenance_at: { bsonType: ['number', 'null'] },
      next_maintenance_at: { bsonType: ['number', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  machine_downtime: {
    bsonType: 'object',
    required: ['machine_id', 'start_time'],
    properties: {
      id: { bsonType: 'string' },
      machine_id: { bsonType: 'string' },
      reason: { bsonType: 'string' },
      start_time: { bsonType: 'number' },
      end_time: { bsonType: ['number', 'null'] },
      duration_minutes: { bsonType: ['number', 'null'] },
      created_at: { bsonType: 'number' },
    },
  },
};
