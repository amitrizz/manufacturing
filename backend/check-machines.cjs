const { MongoClient } = require('mongodb');

async function checkMachines() {
  const uri = "mongodb+srv://amit:amit@cluster0.tysk0hr.mongodb.net/manufacturing?retryWrites=true&w=majority&appName=Cluster0";
  const client = new MongoClient(uri);
  
  try {
    await client.connect();
    const db = client.db('manufacturing');
    
    // Check companies
    const companies = await db.collection('companies').find({}).toArray();
    console.log('Companies:', companies.map(c => ({ id: c.id, _id: c._id, name: c.name, code: c.code })));
    
    // Check machines
    const machines = await db.collection('machines').find({}).toArray();
    console.log('Machines:', machines.map(m => ({ 
      id: m.id, 
      code: m.code, 
      name: m.name, 
      company_id: m.company_id,
      line_id: m.line_id,
      status: m.status 
    })));
    
    // Check production_lines
    const lines = await db.collection('production_lines').find({}).toArray();
    console.log('Lines:', lines.map(l => ({ id: l.id, code: l.code, name: l.name, company_id: l.company_id })));
    
  } catch (err) {
    console.error('Error:', err);
  } finally {
    await client.close();
  }
}

checkMachines();