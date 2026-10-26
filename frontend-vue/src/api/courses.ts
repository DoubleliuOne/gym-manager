import api from "./index";

export interface Course {
  id: number;
  name: string;
  description: string;
  maxCapacity: number;
  durationMinutes: number;
  status: number;
  createdAt?: string;
  updatedAt?: string;
}

export const courseApi = {
  list: () => api.get("/courses") as Promise<{ code: number; msg: string; data: Course[] }>,
  getById: (id: number) => api.get("/courses/" + id) as Promise<{ code: number; msg: string; data: Course }>,
  create: (data: Partial<Course>) => api.post("/courses", data) as Promise<{ code: number; msg: string; data: Course }>,
  update: (id: number, data: Partial<Course>) =>
    api.put("/courses/" + id, data) as Promise<{ code: number; msg: string; data: Course }>,
};
