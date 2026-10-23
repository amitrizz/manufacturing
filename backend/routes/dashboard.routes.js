import { Router } from 'express';
import { connectToMongo, normalizeDoc } from '../config/db.js';

const router = Router();

router.get('/dashboard/stats', async (req, res) => {
  try {
    const database = await connectToMongo();
    const companyId = req.companyId;
    const scope = companyId ? { company_id: companyId } : {};

    const [
      machines,
      attendance,
      activities,
      orders,
      entries,
      inspections,
      materials,
      maintenance,
      lines,
    ] = await Promise.all([
      database.collection('machines').find(scope).toArray(),
      database.collection('staff_attendance').find(scope).toArray(),
      database.collection('activity_history').find(scope).sort({ timestamp: -1, created_at: -1 }).limit(10).toArray(),
      database.collection('production_orders').find(scope).toArray(),
      database.collection('production_entries').find(scope).toArray(),
      database.collection('quality_inspections').find(scope).toArray(),
      database.collection('materials').find(scope).toArray(),
      database.collection('maintenance_orders').find(scope).toArray(),
      database.collection('production_lines').find(scope).toArray(),
    ]);

    // Machine breakdown
    const runningM = machines.filter((m) => m.status === 'RUNNING').length;
    const breakdownM = machines.filter((m) => m.status === 'BREAKDOWN').length;
    const maintenanceM = machines.filter((m) => m.status === 'MAINTENANCE').length;
    const idleM = machines.filter((m) => m.status === 'IDLE' || m.status === 'STOPPED').length;
    const totalM = machines.length;

    // Attendance (Today's date)
    const todayStr = new Date().toISOString().slice(0, 10);
    const todayAttendance = attendance.filter((a) => a.date === todayStr || !a.date);
    const totalStaff = todayAttendance.length;
    const present = todayAttendance.filter((a) => a.status === 'PRESENT').length;
    const halfDay = todayAttendance.filter((a) => a.status === 'HALF_DAY').length;
    const leave = todayAttendance.filter((a) => a.status === 'LEAVE').length;
    const absent = todayAttendance.filter((a) => a.status === 'ABSENT').length;
    const attendanceRate = totalStaff > 0 ? Math.round(((present + halfDay * 0.5) / totalStaff) * 100) : 0;

    // KPIs
    const totalTarget = orders.reduce((sum, o) => sum + (Number(o.target_quantity) || 0), 0);
    const totalProduced = entries.reduce((sum, e) => sum + (Number(e.good_quantity) || 0), 0);
    const totalInspected = inspections.reduce((sum, i) => sum + (Number(i.quantity) || 0), 0);
    const totalRejected = inspections.reduce((sum, i) => sum + (Number(i.rejected_quantity) || 0), 0);
    const totalPassed = totalInspected - totalRejected;
    const qualityRate = totalInspected > 0 ? Math.round((totalPassed / totalInspected) * 100) : 100;
    const achievement = totalTarget > 0 ? Math.min(100, Math.round((totalProduced / totalTarget) * 100)) : 0;

    // Line Progress
    const lineOrderMap = {};
    for (const ord of orders) {
      if (ord.line_id) {
        if (!lineOrderMap[ord.line_id]) lineOrderMap[ord.line_id] = [];
        lineOrderMap[ord.line_id].push(ord.id || ord._id);
      }
    }
    const lineProgress = lines.map((l) => {
      const lId = l.id || l._id;
      const orderIds = lineOrderMap[lId] || [];
      const lineProduced = entries
        .filter((e) => orderIds.includes(e.production_order_id))
        .reduce((sum, e) => sum + (Number(e.good_quantity) || 0), 0);
      const pct = totalProduced > 0 ? Math.round((lineProduced / totalProduced) * 100) : 0;
      return {
        lineCode: l.code,
        lineName: l.name,
        produced: lineProduced,
        pct,
      };
    });

    // Actionable Tasks
    const pendingInspections = inspections.filter((i) => i.status === 'PENDING').length;
    const openMaintenance = maintenance.filter((m) => m.status === 'OPEN' || m.status === 'IN_PROGRESS').length;
    const lowStockMaterials = materials.filter((m) => (m.current_stock || 0) <= (m.min_stock || 0)).length;
    const pendingTasksCount = pendingInspections + openMaintenance + breakdownM + lowStockMaterials;

    // Monthly comparison data (last 6 months)
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const now = new Date();
    const monthlyData = [];
    for (let i = 5; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const mIdx = d.getMonth();
      const mYear = d.getFullYear();
      const mStart = new Date(mYear, mIdx, 1).getTime();
      const mEnd = new Date(mYear, mIdx + 1, 0, 23, 59, 59).getTime();

      const mTarget = orders
        .filter((o) => (o.start_date || o.created_at) >= mStart && (o.start_date || o.created_at) <= mEnd)
        .reduce((sum, o) => sum + (Number(o.target_quantity) || 0), 0);

      const mProduced = entries
        .filter((e) => (e.entry_timestamp || e.created_at) >= mStart && (e.entry_timestamp || e.created_at) <= mEnd)
        .reduce((sum, e) => sum + (Number(e.good_quantity) || 0), 0);

      monthlyData.push({
        month: monthNames[mIdx],
        year: mYear,
        target: mTarget || Math.round(totalTarget / 6) || 0,
        produced: mProduced || Math.round(totalProduced / 6) || 0,
        pct: mTarget > 0 ? Math.min(100, Math.round((mProduced / mTarget) * 100)) : achievement,
      });
    }

    res.json({
      kpis: {
        target: totalTarget,
        produced: totalProduced,
        achievement,
        qualityRate,
        machineAvailability: totalM > 0 ? Math.round((runningM / totalM) * 100) : 0,
        downtimeHours: breakdownM * 2.5 + maintenanceM * 1.5,
        machineStatusCounts: {
          RUNNING: runningM,
          BREAKDOWN: breakdownM,
          MAINTENANCE: maintenanceM,
          IDLE: idleM,
        },
        lineProgress,
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
      recentActivities: activities.map(normalizeDoc),
      monthlyData,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
