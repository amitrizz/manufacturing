import { getDatabase } from '../client';
import type { CompanyRow } from '../../types/database';
import { newId } from '../../utils/id';

export type CreateCompanyInput = {
  name: string;
  company_code: string;
  admin_email: string;
  admin_password: string;
};

export async function listCompanies(): Promise<CompanyRow[]> {
  const db = await getDatabase();
  return db.getAllAsync<CompanyRow>('SELECT * FROM companies ORDER BY name ASC;');
}

export async function getCompanyById(id: string): Promise<CompanyRow | null> {
  const db = await getDatabase();
  return db.getFirstAsync<CompanyRow>('SELECT * FROM companies WHERE id = ?;', id);
}

export async function getCompanyByCode(code: string): Promise<CompanyRow | null> {
  const db = await getDatabase();
  const clean = code.trim().toUpperCase();
  return db.getFirstAsync<CompanyRow>('SELECT * FROM companies WHERE UPPER(company_code) = ?;', clean);
}

export async function getCompanyByEmail(email: string): Promise<CompanyRow | null> {
  const db = await getDatabase();
  const clean = email.trim().toLowerCase();
  return db.getFirstAsync<CompanyRow>('SELECT * FROM companies WHERE LOWER(admin_email) = ?;', clean);
}

export async function createCompany(input: CreateCompanyInput): Promise<CompanyRow> {
  const db = await getDatabase();
  const id = newId();
  const now = Date.now();
  const code = input.company_code.trim().toUpperCase();
  const email = input.admin_email.trim().toLowerCase();
  const name = input.name.trim();
  const password = input.admin_password.trim();

  // Check if code or email already exists
  const existingCode = await db.getFirstAsync<CompanyRow>(
    'SELECT * FROM companies WHERE UPPER(company_code) = ?;',
    code,
  );
  if (existingCode) {
    throw new Error(`Company code "${code}" is already taken. Please choose another.`);
  }

  const existingEmail = await db.getFirstAsync<CompanyRow>(
    'SELECT * FROM companies WHERE LOWER(admin_email) = ?;',
    email,
  );
  if (existingEmail) {
    throw new Error(`Admin email "${email}" is already registered. Please sign in or use another email.`);
  }

  await db.runAsync(
    `INSERT INTO companies (
      id, company_code, name, admin_email, admin_password, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?);`,
    id,
    code,
    name,
    email,
    password,
    now,
    now,
  );

  const created = await getCompanyById(id);
  if (!created) {
    throw new Error('Failed to create company');
  }
  return created;
}

export async function verifyCompanyAdmin(
  emailOrCode: string,
  password: string,
): Promise<CompanyRow | null> {
  const db = await getDatabase();
  const cleanInput = emailOrCode.trim();
  const cleanPass = password.trim();

  const company = await db.getFirstAsync<CompanyRow>(
    `SELECT * FROM companies 
     WHERE (LOWER(admin_email) = LOWER(?) OR UPPER(company_code) = UPPER(?))
       AND admin_password = ?;`,
    cleanInput,
    cleanInput,
    cleanPass,
  );

  return company ?? null;
}
