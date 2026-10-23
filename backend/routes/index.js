import { Router } from 'express';
import healthRoutes from './health.routes.js';
import dashboardRoutes from './dashboard.routes.js';
import machineRoutes from './machine.routes.js';
import productionRoutes from './production.routes.js';
import purchaseRoutes from './purchase.routes.js';
import unitRoutes from './unit.routes.js';
import collectionsRoutes from './collections.routes.js';
import databaseRoutes from './database.routes.js';

const apiRouter = Router();

apiRouter.use(healthRoutes);
apiRouter.use(dashboardRoutes);
apiRouter.use(machineRoutes);
apiRouter.use(productionRoutes);
apiRouter.use(purchaseRoutes);
apiRouter.use(unitRoutes);
apiRouter.use(collectionsRoutes);
apiRouter.use(databaseRoutes);

export default apiRouter;
