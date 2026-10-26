import api from "./index";

export interface CardTemplate {
  id: number;
  name: string;
  type: number;
  durationDays: number;
  totalCount: number;
  price: number;
  status: number;
  createdAt: string;
}

export const cardTemplateApi = {
  list: () => api.get("/cards/templates") as Promise<{ code: number; msg: string; data: CardTemplate[] }>,
  create: (data: Partial<CardTemplate>) =>
    api.post("/cards/templates", data) as Promise<{ code: number; msg: string; data: CardTemplate }>,
  update: (id: number, data: Partial<CardTemplate>) =>
    api.put("/cards/templates/" + id, data) as Promise<{ code: number; msg: string; data: CardTemplate }>,
};
