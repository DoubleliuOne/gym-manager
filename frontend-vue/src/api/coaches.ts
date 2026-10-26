import api from "./index";

export interface Coach {
  id: number;
  name: string;
  phone: string;
  specialty: string;
  status: number;
  createdAt?: string;
  updatedAt?: string;
}

export const coachApi = {
  list: () => api.get("/coaches") as Promise<{ code: number; msg: string; data: Coach[] }>,
  getById: (id: number) => api.get("/coaches/" + id) as Promise<{ code: number; msg: string; data: Coach }>,
  create: (data: { name: string; phone: string; specialty?: string; status?: number }) =>
    api.post("/coaches", data) as Promise<{ code: number; msg: string; data: Coach }>,
  update: (id: number, data: Partial<Coach>) =>
    api.put("/coaches/" + id, data) as Promise<{ code: number; msg: string; data: Coach }>,
  delete: (id: number) => api.delete("/coaches/" + id) as Promise<{ code: number; msg: string; data: null }>,
};
