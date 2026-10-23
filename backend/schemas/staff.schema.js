export const staffSchemas = {
  staff: {
    bsonType: 'object',
    required: ['employee_id', 'name', 'phone'],
    properties: {
      id: { bsonType: 'string' },
      employee_id: { bsonType: 'string' },
      name: { bsonType: 'string' },
      phone: { bsonType: 'string' },
      email: { bsonType: ['string', 'null'] },
      role_id: { bsonType: ['string', 'null'] },
      department: { bsonType: ['string', 'null'] },
      shift: { enum: ['MORNING', 'EVENING', 'NIGHT', 'GENERAL'], bsonType: 'string' },
      hourly_rate: { bsonType: 'number' },
      status: { enum: ['ACTIVE', 'INACTIVE', 'ON_LEAVE'], bsonType: 'string' },
      joined_date: { bsonType: ['number', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },

  staff_attendance: {
    bsonType: 'object',
    required: ['staff_id', 'date', 'status'],
    properties: {
      id: { bsonType: 'string' },
      staff_id: { bsonType: 'string' },
      date: { bsonType: 'string', description: 'YYYY-MM-DD' },
      shift: { bsonType: 'string' },
      status: { enum: ['PRESENT', 'ABSENT', 'HALF_DAY', 'LEAVE'], bsonType: 'string' },
      check_in: { bsonType: ['number', 'null'] },
      check_out: { bsonType: ['number', 'null'] },
      overtime_hours: { bsonType: 'number' },
      notes: { bsonType: ['string', 'null'] },
      created_at: { bsonType: 'number' },
      updated_at: { bsonType: 'number' },
    },
  },
};
