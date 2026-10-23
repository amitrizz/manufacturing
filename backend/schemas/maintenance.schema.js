export const maintenanceSchemas = {
  maintenance_orders: {
    bsonType: 'object',
    required: ['machine_id', 'order_type', 'status'],
    properties: {
      id: { bsonType: 'string' },
      machine_id: { bsonType: 'string' },
      order_type: { enum: ['PREVENTIVE', 'BREAKDOWN', 'CALIBRATION'], bsonType: 'string' },
      priority: { enum: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'], bsonType: 'string' },
      status: { enum: ['OPEN', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'], bsonType: 'string' },
      assigned_to: { bsonType: ['string', 'null'] },
      description: { bsonType: 'string' },
      scheduled_date: { bsonType: ['number', 'null'] },
      completed_at: { bsonType: ['number', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  maintenance_history: {
    bsonType: 'object',
    required: ['machine_id', 'performed_at', 'summary'],
    properties: {
      id: { bsonType: 'string' },
      machine_id: { bsonType: 'string' },
      maintenance_order_id: { bsonType: ['string', 'null'] },
      performed_at: { bsonType: 'number' },
      summary: { bsonType: 'string' },
      cost: { bsonType: ['number', 'null'] },
      created_at: { bsonType: 'number' },
    },
  },
};
