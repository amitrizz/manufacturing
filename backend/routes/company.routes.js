import { Router } from 'express';
import { connectToMongo, normalizeDoc } from '../config/db.js';
import { validate, validateObjectId } from '../middlewares/validation.js';
import { z } from 'zod';
import { ObjectId } from 'mongodb';

const router = Router();

// Company registration schema
const createCompanySchema = z.object({
  name: z.string().min(1).max(200),
  code: z.string().min(1).max(20).optional(),
  admin_email: z.string().email().optional(),
  admin_password: z.string().min(6).optional(),
  contact_email: z.string().email().optional(),
  contact_phone: z.string().max(50).optional(),
  address: z.string().max(500).optional(),
  tax_id: z.string().max(100).optional(),
});

// POST /companies - Register new company (no companyId required)
router.post('/companies', validate(createCompanySchema), async (req, res) => {
  try {
    const database = await connectToMongo();
    const body = req.validatedBody;
    const now = Date.now();

    // Generate company code from name if not provided
    const companyCode = body.code?.trim().toUpperCase() || body.name.trim().toUpperCase().replace(/\s+/g, '-').slice(0, 20);

    // Check if company code already exists
    const existing = await database.collection('companies').findOne({
      $or: [{ company_code: companyCode }, { code: companyCode }]
    });
    if (existing) {
      return res.status(409).json({ error: 'Company code already exists' });
    }

    // Generate ObjectId for company
    const id = new ObjectId().toString();
    const doc = {
      _id: id,
      id,
      name: body.name.trim(),
      code: companyCode,
      company_code: companyCode,
      admin_email: body.admin_email?.trim() || null,
      admin_password: body.admin_password?.trim() || null,
      contact_email: body.contact_email?.trim() || null,
      contact_phone: body.contact_phone?.trim() || null,
      address: body.address?.trim() || null,
      tax_id: body.tax_id?.trim() || null,
      created_at: now,
      updated_at: now,
      subscription: {
        status: 'TRIAL',
        plan: 'FREE_TRIAL',
        trial_days: 7,
        trial_start_date: now,
        trial_end_date: now + (7 * 24 * 60 * 60 * 1000),
        valid_until: now + (7 * 24 * 60 * 60 * 1000),
        created_at: now,
        updated_at: now,
      },
    };

    await database.collection('companies').insertOne(doc);
    res.status(201).json(normalizeDoc(doc));
  } catch (err) {
    if (err.code === 11000) {
      return res.status(409).json({ error: 'Duplicate key error', field: err.keyValue });
    }
    res.status(500).json({ error: err.message });
  }
});

// GET /companies - List companies (no companyId required for global list)
router.get('/companies', async (req, res) => {
  try {
    const database = await connectToMongo();
    const companies = await database.collection('companies').find({}).sort({ created_at: -1 }).toArray();
    res.json({ data: companies.map(normalizeDoc) });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /companies/:id - Get company by ID
router.get('/companies/:id', validateObjectId('id'), async (req, res) => {
  try {
    const database = await connectToMongo();
    const { id } = req.params;
    
    let idFilter = { $or: [{ id }, { _id: id }] };
    if (require('mongodb').ObjectId.isValid(id)) {
      idFilter.$or.push({ _id: new (require('mongodb').ObjectId)(id) });
    }

    const doc = await database.collection('companies').findOne(idFilter);
    if (!doc) return res.status(404).json({ error: 'Company not found' });
    res.json(normalizeDoc(doc));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /companies/verify-admin - Verify company admin credentials
router.post('/companies/verify-admin', async (req, res) => {
  try {
    const database = await connectToMongo();
    const { emailOrCode, password } = req.body || {};
    
    if (!emailOrCode || !password) {
      return res.status(400).json({ error: 'Email/code and password required' });
    }

    const query = emailOrCode.includes('@') 
      ? { admin_email: emailOrCode.toLowerCase() }
      : { $or: [{ company_code: emailOrCode.toUpperCase() }, { code: emailOrCode.toUpperCase() }] };

    const company = await database.collection('companies').findOne(query);
    
    if (!company || company.admin_password !== password) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    res.json({
      id: company.id || company._id,
      name: company.name,
      code: company.company_code || company.code,
      admin_email: company.admin_email,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;