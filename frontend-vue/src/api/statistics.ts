import api from "./index";

export interface DashboardData {
  totalMembers: number;
  totalCourses: number;
  totalCoaches: number;
  todayBookings: number;
}
export interface CourseBookingStat {
  date: string;
  courseName: string;
  coachName: string;
  booked: number;
  capacity: number;
  occupancyRate: number;
}

export const statisticsApi = {
  dashboard: () => api.get("/statistics/dashboard") as Promise<{ code: number; msg: string; data: DashboardData }>,
  courseBookings: (params?: { start?: string; end?: string }) =>
    api.get("/statistics/course-bookings", { params }) as Promise<{ code: number; msg: string; data: CourseBookingStat[] }>,
  memberRenewals: (params?: { memberId?: number }) =>
    api.get("/statistics/member-renewals", { params }) as Promise<{ code: number; msg: string; data: any[] }>,
};
