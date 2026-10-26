import api from "./index";

export interface CourseSchedule {
  id: number;
  courseId: number;
  coachId: number;
  classDate: string;
  startTime: string;
  endTime: string;
  actualCapacity: number;
  bookedCount: number;
  status: number;
  createdAt?: string;
  updatedAt?: string;
}

export const scheduleApi = {
  list: (params?: { date?: string }) =>
    api.get("/schedules", { params }) as Promise<{ code: number; msg: string; data: CourseSchedule[] }>,
  getById: (id: number) => api.get("/schedules/" + id) as Promise<{ code: number; msg: string; data: CourseSchedule }>,
  create: (data: Partial<CourseSchedule>) => api.post("/schedules", data) as Promise<{ code: number; msg: string; data: CourseSchedule }>,
  update: (id: number, data: Partial<CourseSchedule>) =>
    api.put("/schedules/" + id, data) as Promise<{ code: number; msg: string; data: CourseSchedule }>,
  cancel: (id: number) => api.delete("/schedules/" + id) as Promise<{ code: number; msg: string; data: null }>,
};
