<template>
  <a-layout v-if="authStore.isLoggedIn" style="min-height: 100vh">
    <a-layout-sider breakpoint="lg" :collapsed-width="60" theme="dark">
      <div class="logo">🏋️ 健身房</div>
      <a-menu
        v-model:selectedKeys="selectedKeys"
        theme="dark"
        mode="inline"
        @click="handleMenuClick"
      >
        <a-menu-item key="/dashboard"><dashboard-outlined />仪表盘</a-menu-item>
        <a-menu-item key="/members"><user-outlined />会员管理</a-menu-item>
        <a-menu-item key="/cards/templates"><idcard-outlined />卡模板</a-menu-item>
        <a-menu-item key="/cards/member-cards"><credit-card-outlined />会员卡</a-menu-item>
        <a-menu-item key="/coaches"><team-outlined />教练管理</a-menu-item>
        <a-menu-item key="/courses"><book-outlined />课程管理</a-menu-item>
        <a-menu-item key="/schedules"><calendar-outlined />排课管理</a-menu-item>
        <a-menu-item key="/bookings"><file-text-outlined />预订管理</a-menu-item>
      </a-menu>
    </a-layout-sider>
    <a-layout>
      <a-layout-header class="header">
        <span class="header-user">{{ authStore.member?.name }} ({{ authStore.member?.phone }})</span>
        <a-button type="text" @click="handleLogout">
          <template #icon><logout-outlined /></template>退出
        </a-button>
      </a-layout-header>
      <a-layout-content class="content">
        <router-view />
      </a-layout-content>
    </a-layout>
  </a-layout>
</template>

<script setup lang="ts">
import { ref, watch, onMounted } from "vue";
import { useRouter, useRoute } from "vue-router";
import {
  DashboardOutlined, UserOutlined, IdcardOutlined, CreditCardOutlined,
  TeamOutlined, BookOutlined, CalendarOutlined, FileTextOutlined,
  LogoutOutlined,
} from "@ant-design/icons-vue";
import { useAuthStore } from "../stores/auth";

const router = useRouter();
const route = useRoute();
const authStore = useAuthStore();

const selectedKeys = ref<string[]>(["/dashboard"]);

onMounted(() => {
  authStore.loadFromStorage();
  if (!authStore.isLoggedIn) {
    router.replace("/login");
  }
  updateSelectedKey();
});

watch(() => route.path, updateSelectedKey);

function updateSelectedKey() {
  const p = "/" + route.path.split("/").slice(1, 3).join("/");
  selectedKeys.value = [p];
}

function handleMenuClick({ key }: { key: string }) {
  router.push(key);
}

function handleLogout() {
  authStore.logout();
  router.replace("/login");
}
</script>

<style scoped>
.logo {
  height: 48px;
  margin: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  font-weight: 700;
  font-size: 16px;
}
.header {
  background: #fff;
  padding: 0 24px;
  display: flex;
  align-items: center;
  justify-content: flex-end;
  border-bottom: 1px solid #f0f0f0;
}
.header-user {
  margin-right: 16px;
  color: rgba(0, 0, 0, 0.45);
}
.content {
  margin: 16px;
  padding: 20px;
  background: #fff;
  border-radius: 8px;
  min-height: 280px;
}
</style>
