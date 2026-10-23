export const auditSchemas = {
  activity_history: {
    bsonType: 'object',
    required: ['event_type', 'title'],
    properties: {
      id: { bsonType: 'string' },
      event_type: { bsonType: 'string' },
      title: { bsonType: 'string' },
      description: { bsonType: ['string', 'null'] },
      reference_type: { bsonType: ['string', 'null'] },
      reference_id: { bsonType: ['string', 'null'] },
      timestamp: { bsonType: 'number' },
      created_at: { bsonType: 'number' },
    },
  },

  notifications: {
    bsonType: 'object',
    required: ['title'],
    properties: {
      id: { bsonType: 'string' },
      title: { bsonType: 'string' },
      body: { bsonType: ['string', 'null'] },
      severity: { enum: ['INFO', 'WARNING', 'CRITICAL'], bsonType: 'string' },
      is_read: { bsonType: ['boolean', 'number'] },
      reference_type: { bsonType: ['string', 'null'] },
      reference_id: { bsonType: ['string', 'null'] },
      created_at: { bsonType: 'number' },
    },
  },
};
