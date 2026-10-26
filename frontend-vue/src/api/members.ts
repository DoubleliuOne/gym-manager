import api from "./index";
import type { MemberInfo } from "./auth";

export type { MemberInfo };

export interface MemberPageRes {
  total: number;
  page: number;
  size: number;
  records: MemberInfo[];
}
export interface MemberCard {
  id: number;
  memberId: number;
  templateId: number;
  startDate: string;
  endDate: string;
  remainingCount: number;
  status: number;
  createdAt: string;
}

export const memberApi = {
  list: (params?: { page?: number; size?: number; keyword?: string }) =>
    api.get("/members", { params }) as Promise<{ code: number; msg: string; data: MemberPageRes }>,
  getById: (id: number) =>
    api.get("/members/" + id) as Promise<{ code: number; msg: string; data: MemberInfo }>,
  create: (data: { name: string; phone: string; gender?: number; status?: number }) =>
    api.post("/members", data) as Promise<{ code: number; msg: string; data: MemberInfo }>,
  update: (id: number, data: Partial<MemberInfo>) =>
    api.put("/members/" + id, data) as Promise<{ code: number; msg: string; data: MemberInfo }>,
  updateStatus: (id: number, status: number) =>
    api.put("/members/" + id + "/status", { status }) as Promise<{ code: number; msg: string; data: null }>,
  getCards: (id: number) =>
    api.get("/members/" + id + "/cards") as Promise<{ code: number; msg: string; data: MemberCard[] }>,
};
