const { MongoClient } = require('mongodb');

async function addCompany() {
  const uri = "mongodb+srv://amit:amit@cluster0.tysk0hr.mongodb.net/manufacturing?retryWrites=true&w=majority&appName=Cluster0";
  const client = new MongoClient(uri);
  
  try {
    await client.connect();
    const db = client.db('manufacturing');
    
    const companyId = '05cf18e5-026d-4cb1-a312-e831dcd30e6b';
    const now = Date.now();
    
    await db.collection('companies').insertOne({
      _id: companyId,
      id: companyId,
      name: 'ABCD Company',
      code: 'ABCD',
      company_code: 'ABCD',
      created_at: now,
      updated_at: now,
    });
    
    console.log('Company added:', companyId);
    
    // Verify
    const companies = await db.collection('companies').find({}).toArray();
    console.log('Companies:', companies);
    
  } catch (err) {
    console.error('Error:', err);
  } finally {
    await client.close();
  }
}

addCompany();