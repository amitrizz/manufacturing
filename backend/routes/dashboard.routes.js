import { Router } from 'express';
import { connectToMongo, normalizeDoc } from '../config/db.js';
import { validate, dateRangeSchema } from '../middlewares/validation.js';

const router = Router();

// Helper: Build date range filter for timestamp fields
const buildDateFilter = (field, start, end) => {
  if (!start && !end) return {};
  const filter = {};
  if (start) filter[field] = { ...filter[field], $gte: start };
  if (end) filter[field] = { ...filter[field], $lte: end };
  return filter;
};

// Helper: Build company scope filter
const buildScope = (companyId) => companyId ? { company_id: companyId } : {};

/**
 * GET /dashboard/stats
 * Optimized with MongoDB aggregation pipelines for server-side computation
 */
router.get('/dashboard/stats', validate(dateRangeSchema), async (req, res) => {
  try {
    const database = await connectToMongo();
    const companyId = req.companyId;
    const scope = buildScope(companyId);
    const { start, end } = req.validatedQuery || {};
    
    // Default to last 30 days if no range provided
    const rangeStart = start || Date.now() - 30 * 24 * 60 * 60 * 1000;
    const rangeEnd = end || Date.now();
    const todayStr = new Date().toISOString().slice(0, 10);

    // Parallel aggregation pipelines
    const [
      machineStats,
      attendanceStats,
      recentActivities,
      productionKpis,
      qualityStats,
      materialAlerts,
      maintenanceStats,
      lineProgress,
      monthlyData,
    ] = await Promise.all([
      // 1. Machine status counts (aggregation)
      database.collection('machines').aggregate([
        { $match: scope },
        { $group: { _id: '$status', count: { $sum: 1 } } },
        { $project: { _id: 0, status: '$_id', count: 1 } },
      ]).toArray(),

      // 2. Today's attendance (aggregation)
      database.collection('staff_attendance').aggregate([
        { $match: { ...scope, $or: [{ date: todayStr }, { date: { $exists: false } }] } },
        { $group: { 
          _id: '$status', 
          count: { $sum: 1 } 
        }},
        { $project: { _id: 0, status: '$_id', count: 1 } },
      ]).toArray(),

      // 3. Recent activities (limited, sorted)
      database.collection('activity_history')
        .find(scope)
        .sort({ timestamp: -1, created_at: -1 })
        .limit(10)
        .toArray(),

      // 4. Production KPIs (aggregation)
      database.collection('production_orders').aggregate([
        { $match: { ...scope, ...buildDateFilter('start_date', rangeStart, rangeEnd) } },
        { $group: { 
          _id: null, 
          totalTarget: { $sum: { $toDouble: '$target_quantity' } },
          orderIds: { $push: '$_id' },
          lineIds: { $push: '$line_id' },
        }},
      ]).toArray(),

      // 5. Quality stats (aggregation)
      database.collection('quality_inspections').aggregate([
        { $match: { ...scope, ...buildDateFilter('inspected_at', rangeStart, rangeEnd) } },
        { $group: { 
          _id: null, 
          totalInspected: { $sum: { $toDouble: '$quantity' } },
          totalRejected: { $sum: { $toDouble: '$rejected_quantity' } },
          pendingCount: { $sum: { $cond: [{ $eq: ['$status', 'PENDING'] }, 1, 0] } },
        }},
      ]).toArray(),

      // 6. Low stock materials count
      database.collection('materials').countDocuments({
        ...scope,
        $expr: { $lte: ['$current_stock', '$min_stock'] },
      }),

      // 7. Open maintenance orders
      database.collection('maintenance_orders').countDocuments({
        ...scope,
        status: { $in: ['OPEN', 'IN_PROGRESS'] },
      }),

      // 8. Line progress (aggregation with lookup)
      database.collection('production_lines').aggregate([
        { $match: scope },
        { $lookup: {
          from: 'production_orders',
          localField: '_id',
          foreignField: 'line_id',
          as: 'orders',
          pipeline: [
            { $match: { ...scope, ...buildDateFilter('start_date', rangeStart, rangeEnd) } },
            { $project: { _id: 1 } },
          ],
        }},
        { $lookup: {
          from: 'production_entries',
          localField: 'orders._id',
          foreignField: 'production_order_id',
          as: 'entries',
          pipeline: [
            { $match: { ...scope, ...buildDateFilter('entry_timestamp', rangeStart, rangeEnd) } },
            { $project: { good_quantity: 1, production_order_id: 1 } },
          ],
        }},
        { $project: {
          _id: 0,
          lineCode: '$code',
          lineName: '$name',
          produced: { $sum: '$entries.good_quantity' },
        }},
      ]).toArray(),

      // 9. Monthly comparison (last 6 months) - aggregation
      database.collection('production_orders').aggregate([
        { $match: { ...scope, ...buildDateFilter('start_date', rangeStart, rangeEnd) } },
        { $group: {
          _id: {
            year: { $year: { $toDate: '$start_date' } },
            month: { $month: { $toDate: '$start_date' } },
          },
          target: { $sum: { $toDouble: '$target_quantity' } },
          orderIds: { $push: '$_id' },
        }},
        { $lookup: {
          from: 'production_entries',
          localField: 'orderIds',
          foreignField: 'production_order_id',
          as: 'entries',
          pipeline: [
            { $match: { ...scope, ...buildDateFilter('entry_timestamp', rangeStart, rangeEnd) } },
            { $project: { good_quantity: 1 } },
          ],
        }},
        { $project: {
          _id: 0,
          year: '$_id.year',
          month: '$_id.month',
          target: 1,
          produced: { $sum: '$entries.good_quantity' },
        }},
        { $sort: { year: 1, month: 1 } },
      ]).toArray(),
    ]);

    // Process machine stats
    const machineStatusCounts = { RUNNING: 0, BREAKDOWN: 0, MAINTENANCE: 0, IDLE: 0 };
    for (const m of machineStats) {
      if (machineStatusCounts.hasOwnProperty(m.status)) {
        machineStatusCounts[m.status] = m.count;
      } else if (m.status === 'STOPPED') {
        machineStatusCounts.IDLE += m.count;
      }
    }
    const totalM = Object.values(machineStatusCounts).reduce((a, b) => a + b, 0);
    const runningM = machineStatusCounts.RUNNING;
    const breakdownM = machineStatusCounts.BREAKDOWN;
    const maintenanceM = machineStatusCounts.MAINTENANCE;
    const idleM = machineStatusCounts.IDLE;

    // Process attendance stats
    const attendanceCounts = { PRESENT: 0, HALF_DAY: 0, LEAVE: 0, ABSENT: 0 };
    for (const a of attendanceStats) {
      if (attendanceCounts.hasOwnProperty(a.status)) {
        attendanceCounts[a.status] = a.count;
      }
    }
    const totalStaff = Object.values(attendanceCounts).reduce((a, b) => a + b, 0);
    const present = attendanceCounts.PRESENT;
    const halfDay = attendanceCounts.HALF_DAY;
    const leave = attendanceCounts.LEAVE;
    const absent = attendanceCounts.ABSENT;
    const attendanceRate = totalStaff > 0 ? Math.round(((present + halfDay * 0.5) / totalStaff) * 100) : 0;

    // Process production KPIs
    const prodKpi = productionKpis[0] || { totalTarget: 0, orderIds: [], lineIds: [] };
    const totalTarget = Math.round(prodKpi.totalTarget || 0);

    // Get produced quantity from entries
    const entriesResult = await database.collection('production_entries').aggregate([
      { $match: { ...scope, production_order_id: { $in: prodKpi.orderIds }, ...buildDateFilter('entry_timestamp', rangeStart, rangeEnd) } },
      { $group: { _id: null, totalProduced: { $sum: { $toDouble: '$good_quantity' } } } },
    ]).toArray();
    const totalProduced = Math.round(entriesResult[0]?.totalProduced || 0);

    // Process quality stats
    const quality = qualityStats[0] || { totalInspected: 0, totalRejected: 0, pendingCount: 0 };
    const totalInspected = quality.totalInspected || 0;
    const totalRejected = quality.totalRejected || 0;
    const totalPassed = totalInspected - totalRejected;
    const qualityRate = totalInspected > 0 ? Math.round((totalPassed / totalInspected) * 100) : 100;
    const pendingInspections = quality.pendingCount || 0;

    const achievement = totalTarget > 0 ? Math.min(100, Math.round((totalProduced / totalTarget) * 100)) : 0;

    // Process line progress
    const totalLineProduced = lineProgress.reduce((sum, l) => sum + (l.produced || 0), 0);
    const processedLineProgress = lineProgress.map(l => ({
      lineCode: l.lineCode,
      lineName: l.lineName,
      produced: l.produced || 0,
      pct: totalLineProduced > 0 ? Math.round((l.produced / totalLineProduced) * 100) : 0,
    }));

    // Actionable tasks
    const openMaintenance = maintenanceStats;
    const lowStockMaterials = materialAlerts;
    const pendingTasksCount = pendingInspections + openMaintenance + breakdownM + lowStockMaterials;

    // Process monthly data
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const processedMonthlyData = monthlyData.map(m => ({
      month: monthNames[m.month - 1],
      year: m.year,
      target: Math.round(m.target || 0),
      produced: Math.round(m.produced || 0),
      pct: m.target > 0 ? Math.min(100, Math.round((m.produced / m.target) * 100)) : achievement,
    }));

    // Ensure we have 6 months of data (fill gaps)
    const now = new Date();
    const finalMonthlyData = [];
    for (let i = 5; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const existing = processedMonthlyData.find(m => m.year === d.getFullYear() && m.month === monthNames[d.getMonth()]);
      if (existing) {
        finalMonthlyData.push(existing);
      } else {
        finalMonthlyData.push({
          month: monthNames[d.getMonth()],
          year: d.getFullYear(),
          target: Math.round(totalTarget / 6) || 0,
          produced: Math.round(totalProduced / 6) || 0,
          pct: achievement,
        });
      }
    }

    res.json({
      kpis: {
        target: totalTarget,
        produced: totalProduced,
        achievement,
        qualityRate,
        machineAvailability: totalM > 0 ? Math.round((runningM / totalM) * 100) : 0,
        downtimeHours: Math.round((breakdownM * 2.5 + maintenanceM * 1.5) * 10) / 10,
        machineStatusCounts,
        lineProgress: processedLineProgress,
      },
      machines: {
        running: runningM,
        breakdown: breakdownM,
        maintenance: maintenanceM,
        idle: idleM,
        total: totalM,
      },
      attendance: {
        total: totalStaff,
        present,
        halfDay,
        leave,
        absent,
        rate: attendanceRate,
      },
      pendingTasksCount,
      recentActivities: recentActivities.map(a => {
        const norm = normalizeDoc(a) || {};
        return {
          ...norm,
          eventType: norm.event_type || norm.eventType || 'ACTIVITY',
          event_type: norm.event_type || norm.eventType || 'ACTIVITY',
          referenceType: norm.reference_type || norm.referenceType || null,
          referenceId: norm.reference_id || norm.referenceId || null,
          companyId: norm.company_id || norm.companyId || null,
        };
      }),
      monthlyData: finalMonthlyData,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
