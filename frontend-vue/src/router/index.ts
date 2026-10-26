import { createRouter, createWebHistory } from "vue-router";
import MainLayout from "../layouts/MainLayout.vue";

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: "/login",
      name: "Login",
      component: () => import("../views/Login.vue"),
    },
    {
      path: "/",
      component: MainLayout,
      redirect: "/dashboard",
      children: [
        {
          path: "dashboard",
          name: "Dashboard",
          component: () => import("../views/Dashboard.vue"),
        },
        {
          path: "members",
          name: "MemberList",
          component: () => import("../views/members/MemberList.vue"),
        },
        {
          path: "members/:id",
          name: "MemberDetail",
          component: () => import("../views/members/MemberDetail.vue"),
        },
        {
          path: "cards/templates",
          name: "CardTemplates",
          component: () => import("../views/cards/CardTemplates.vue"),
        },
        {
          path: "cards/member-cards",
          name: "MemberCards",
          component: () => import("../views/cards/MemberCards.vue"),
        },
        {
          path: "coaches",
          name: "CoachList",
          component: () => import("../views/coaches/CoachList.vue"),
        },
        {
          path: "courses",
          name: "CourseList",
          component: () => import("../views/courses/CourseList.vue"),
        },
        {
          path: "schedules",
          name: "ScheduleList",
          component: () => import("../views/schedules/ScheduleList.vue"),
        },
        {
          path: "bookings",
          name: "BookingList",
          component: () => import("../views/bookings/BookingList.vue"),
        },
      ],
    },
  ],
});

export default router;
