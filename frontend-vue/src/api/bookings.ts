import api from "./index";

export interface Booking {
  id: number;
  memberId: number;
  scheduleId: number;
  status: number;
  createdAt?: string;
  updatedAt?: string;
}
export interface CheckInRecord {
  id: number;
  bookingId: number;
  memberId: number;
  method: number;
  checkinTime: string;
}

export const bookingApi = {
  list: (params?: { memberId?: number; scheduleId?: number }) =>
    api.get("/bookings", { params }) as Promise<{ code: number; msg: string; data: Booking[] }>,
  create: (data: { memberId: number; scheduleId: number }) =>
    api.post("/bookings", data) as Promise<{ code: number; msg: string; data: Booking }>,
  cancel: (id: number, data: { memberId: number }) =>
    api.put("/bookings/" + id + "/cancel", data) as Promise<{ code: number; msg: string; data: null }>,
  checkin: (data: { bookingId: number; method: number }) =>
    api.post("/bookings/checkin", data) as Promise<{ code: number; msg: string; data: null }>,
  checkins: (params?: { memberId?: number }) =>
    api.get("/bookings/checkins", { params }) as Promise<{ code: number; msg: string; data: CheckInRecord[] }>,
  memberBookings: (memberId: number) =>
    api.get("/bookings/member/" + memberId) as Promise<{ code: number; msg: string; data: Booking[] }>,
};
