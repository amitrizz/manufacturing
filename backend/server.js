import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { connectToMongo, DB_NAME } from './config/db.js';
import apiRoutes from './routes/index.js';
import { errorHandler } from './middlewares/errorHandler.js';
import { tenantMiddleware } from './middlewares/tenant.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// Standard Middlewares
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(tenantMiddleware);

// Mount Modular API Routes
app.use('/api', apiRoutes);

// Root Welcome & Health Check
app.get('/', (req, res) => {
  res.json({
    name: 'Manufacturing ERP Backend API',
    status: 'running',
    version: '2.0.0',
    documentation: '/api/health',
  });
});

// Global Error Handler
app.use(errorHandler);

// Start Server
app.listen(PORT, '0.0.0.0', async () => {
  console.log(`--------------------------------------------------`);
  console.log(`🚀 Modular Manufacturing MongoDB Backend Server`);
  console.log(`📡 URL: http://0.0.0.0:${PORT}`);
  console.log(`📦 Database: ${DB_NAME}`);
  console.log(`🌐 Cluster: cluster0.tysk0hr.mongodb.net`);
  console.log(`--------------------------------------------------`);
  try {
    await connectToMongo();
  } catch (err) {
    console.error('Failed to connect to MongoDB on startup:', err.message);
  }
});

export default app;
