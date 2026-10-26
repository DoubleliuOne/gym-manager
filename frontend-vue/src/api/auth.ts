import api from "./index";

export interface LoginReq {
  phone: string;
  password: string;
}
export interface RegisterReq {
  phone: string;
  password: string;
  name: string;
}
export interface MemberInfo {
  id: number;
  name: string;
  phone: string;
  gender: number;
  birthday: string | null;
  avatarUrl: string | null;
  status: number;
  role: number;
  createdAt: string;
  updatedAt: string;
}
export interface LoginRes {
  token: string;
  member: MemberInfo;
}

export const authApi = {
  login: (data: LoginReq & { source?: string }) => api.post("/auth/login", data) as Promise<{ code: number; msg: string; data: LoginRes }>,
  register: (data: RegisterReq) => api.post("/auth/register", data) as Promise<{ code: number; msg: string; data: null }>,
};
