import { Router } from 'express';
import { requireCompanyAccess } from '../middlewares/validation.js';
import healthRoutes from './health.routes.js';
import dashboardRoutes from './dashboard.routes.js';
import machineRoutes from './machine.routes.js';
import productionRoutes from './production.routes.js';
import purchaseRoutes from './purchase.routes.js';
import unitRoutes from './unit.routes.js';
import collectionsRoutes from './collections.routes.js';
import databaseRoutes from './database.routes.js';

const apiRouter = Router();

// Health check (no auth required)
apiRouter.use(healthRoutes);

// Company registration and Subscription / Payment (flexible company resolution)
import companyRoutes from './company.routes.js';
import paymentRoutes from './payment.routes.js';
apiRouter.use(companyRoutes);
apiRouter.use(paymentRoutes);

// Require company access for all multi-tenant routes
apiRouter.use(requireCompanyAccess);

apiRouter.use(dashboardRoutes);
apiRouter.use(machineRoutes);
apiRouter.use(productionRoutes);
apiRouter.use(purchaseRoutes);
apiRouter.use(unitRoutes);
apiRouter.use(collectionsRoutes);
apiRouter.use(databaseRoutes);

export default apiRouter;
