<template>
  <div class="login-wrap">
    <a-card class="login-card">
      <h2 style="text-align: center; margin-bottom: 24px">🏋️ 健身房管理系统</h2>
      <a-form :model="loginForm" @finish="handleLogin" autocomplete="off" size="large">
        <a-form-item name="phone" :rules="[{ required: true, message: '请输入管理员手机号' }]">
          <a-input v-model:value="loginForm.phone" placeholder="管理员手机号">
            <template #prefix><phone-outlined /></template>
          </a-input>
        </a-form-item>
        <a-form-item name="password" :rules="[{ required: true, message: '请输入密码' }]">
          <a-input-password v-model:value="loginForm.password" placeholder="密码">
            <template #prefix><lock-outlined /></template>
          </a-input-password>
        </a-form-item>
        <a-form-item>
          <a-button type="primary" html-type="submit" :loading="loading" block>登录</a-button>
        </a-form-item>
      </a-form>
    </a-card>
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";
import { useRouter } from "vue-router";
import { message } from "ant-design-vue";
import { PhoneOutlined, LockOutlined } from "@ant-design/icons-vue";
import { authApi } from "../api/auth";
import { useAuthStore } from "../stores/auth";

const router = useRouter();
const authStore = useAuthStore();
const loading = ref(false);

const loginForm = ref({ phone: "", password: "" });

async function handleLogin() {
  loading.value = true;
  try {
    const res = await authApi.login({ ...loginForm.value, source: "admin" });
    if (res.data.member.role !== 1) {
      message.error("该账号无管理员权限");
      return;
    }
    authStore.setAuth(res.data.token, res.data.member);
    message.success("登录成功");
    router.replace("/dashboard");
  } catch (e: any) {
    message.error(e.message || "登录失败");
  } finally {
    loading.value = false;
  }
}
</script>

<style scoped>
.login-wrap {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f0f2f5;
}
.login-card {
  width: 400px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}
</style>
