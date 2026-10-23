import { mongoApi } from '../client';
import type { CompanyRow } from '../../types/database';
import { newId } from '../../utils/id';

export type CreateCompanyInput = {
  name: string;
  company_code: string;
  admin_email: string;
  admin_password: string;
};

export async function listCompanies(): Promise<CompanyRow[]> {
  try {
    const list = await mongoApi.getCollection<CompanyRow>('companies');
    if (list && Array.isArray(list)) {
      return list.sort((a, b) => (a.name || '').localeCompare(b.name || ''));
    }
  } catch (err) {
    console.warn('MongoDB listCompanies error:', err);
  }
  return [];
}

export async function getCompanyById(id: string): Promise<CompanyRow | null> {
  try {
    const comp = await mongoApi.getById<CompanyRow>('companies', id);
    if (comp) return comp;
  } catch {
    const all = await listCompanies();
    return all.find((c) => c.id === id || (c as any)._id === id) || null;
  }
  return null;
}

export async function getCompanyByCode(code: string): Promise<CompanyRow | null> {
  const clean = code.trim().toUpperCase();
  try {
    const all = await listCompanies();
    return all.find((c) => (c.company_code || (c as any).code)?.toUpperCase() === clean) || null;
  } catch {
    return null;
  }
}

export async function getCompanyByEmail(email: string): Promise<CompanyRow | null> {
  const clean = email.trim().toLowerCase();
  try {
    const all = await listCompanies();
    return all.find((c) => (c.admin_email || (c as any).email)?.toLowerCase() === clean) || null;
  } catch {
    return null;
  }
}

export async function createCompany(input: CreateCompanyInput): Promise<CompanyRow> {
  const id = newId();
  const now = Date.now();
  const code = input.company_code.trim().toUpperCase();
  const email = input.admin_email.trim().toLowerCase();
  const name = input.name.trim();
  const password = input.admin_password.trim();

  const existingByCode = await getCompanyByCode(code);
  if (existingByCode) {
    throw new Error(`Company code "${code}" is already taken. Please choose another.`);
  }

  const existingByEmail = await getCompanyByEmail(email);
  if (existingByEmail) {
    throw new Error(`Admin email "${email}" is already registered. Please sign in or use another email.`);
  }

  const doc: CompanyRow = {
    id,
    company_code: code,
    name,
    admin_email: email,
    admin_password: password,
    created_at: now,
    updated_at: now,
  };

  await mongoApi.insert('companies', {
    ...doc,
    _id: id,
  });

  return doc;
}

export async function verifyCompanyAdmin(
  emailOrCode: string,
  password: string,
): Promise<CompanyRow | null> {
  const cleanInput = emailOrCode.trim();
  const cleanPass = password.trim();

  try {
    const all = await listCompanies();
    const found = all.find(
      (c) =>
        ((c.admin_email || (c as any).email)?.toLowerCase() === cleanInput.toLowerCase() ||
          (c.company_code || (c as any).code)?.toUpperCase() === cleanInput.toUpperCase()) &&
        c.admin_password === cleanPass,
    );
    if (found) return found;
  } catch (err) {
    console.warn('verifyCompanyAdmin error:', err);
  }

  return null;
}
