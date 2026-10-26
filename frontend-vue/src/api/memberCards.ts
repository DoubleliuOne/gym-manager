import api from "./index";

export interface IssueCardReq {
  memberId: number;
  templateId: number;
}
export interface RenewReq {
  memberId: number;
  cardId: number;
  templateId: number;
  amount: number;
  paymentMethod: number;
  remark?: string;
}
export interface RenewalRecord {
  id: number;
  memberId: number;
  cardId: number;
  templateId: number;
  amount: number;
  paymentMethod: number;
  remark: string;
  createdAt: string;
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

export const memberCardApi = {
  issue: (data: IssueCardReq) => api.post("/cards/issue", data) as Promise<{ code: number; msg: string; data: MemberCard }>,
  renewals: (params?: { memberId?: number }) =>
    api.get("/cards/renewals", { params }) as Promise<{ code: number; msg: string; data: RenewalRecord[] }>,
  disable: (id: number) => api.put("/cards/" + id + "/disable"),
  reactivate: (id: number) => api.put("/cards/" + id + "/reactivate") as Promise<{ code: number; msg: string; data: null }>,
  delete: (id: number) => api.delete("/cards/" + id) as Promise<{ code: number; msg: string; data: null }>,
};
