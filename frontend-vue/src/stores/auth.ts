import { defineStore } from "pinia";
import type { MemberInfo } from "../api/auth";

interface AuthState {
  token: string | null;
  member: MemberInfo | null;
}

export const useAuthStore = defineStore("auth", {
  state: (): AuthState => ({
    token: null,
    member: null,
  }),
  getters: {
    isLoggedIn: (state) => !!state.token,
  },
  actions: {
    setAuth(token: string, member: MemberInfo) {
      this.token = token;
      this.member = member;
      localStorage.setItem("token", token);
      localStorage.setItem("member", JSON.stringify(member));
    },
    logout() {
      this.token = null;
      this.member = null;
      localStorage.removeItem("token");
      localStorage.removeItem("member");
    },
    loadFromStorage() {
      const token = localStorage.getItem("token");
      const memberStr = localStorage.getItem("member");
      if (token && memberStr) {
        try {
          this.token = token;
          this.member = JSON.parse(memberStr);
        } catch {
          localStorage.removeItem("token");
          localStorage.removeItem("member");
        }
      }
    },
  },
});
