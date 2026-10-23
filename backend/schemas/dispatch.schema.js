export const dispatchSchemas = {
  finished_goods: {
    bsonType: 'object',
    required: ['product_id', 'quantity'],
    properties: {
      id: { bsonType: 'string' },
      product_id: { bsonType: 'string' },
      production_order_id: { bsonType: ['string', 'null'] },
      batch_number: { bsonType: ['string', 'null'] },
      quantity: { bsonType: 'number' },
      location: { bsonType: ['string', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  dispatch_orders: {
    bsonType: 'object',
    required: ['dispatch_number', 'customer_name', 'product_id', 'quantity', 'status'],
    properties: {
      id: { bsonType: 'string' },
      dispatch_number: { bsonType: 'string' },
      customer_id: { bsonType: ['string', 'null'] },
      customer_name: { bsonType: 'string' },
      product_id: { bsonType: 'string' },
      quantity: { bsonType: 'number' },
      status: { enum: ['PENDING', 'READY', 'DISPATCHED', 'DELIVERED', 'CANCELLED'], bsonType: 'string' },
      dispatched_at: { bsonType: ['number', 'null'] },
      delivery_address: { bsonType: ['string', 'null'] },
      vehicle_number: { bsonType: ['string', 'null'] },
      driver_name: { bsonType: ['string', 'null'] },
      notes: { bsonType: ['string', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },
};
