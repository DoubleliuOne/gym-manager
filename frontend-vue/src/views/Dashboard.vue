<template>
  <div>
    <a-row :gutter="[16, 16]">
      <a-col v-for="card in statCards" :key="card.title" :xs="12" :sm="12" :md="6">
        <a-card>
          <a-statistic :title="card.title" :value="card.value">
            <template #prefix>
              <span :style="{ color: card.color }"><component :is="card.icon" /></span>
            </template>
          </a-statistic>
        </a-card>
      </a-col>
    </a-row>
    <a-card title="课程预约统计" :style="{ marginTop: 16 }">
      <template #extra>
        <a-range-picker v-model:value="dateRange" @change="onDateChange" />
      </template>
      <a-table
        rowKey="rowKey"
        :columns="columns"
        :dataSource="courseStats"
        :pagination="false"
        size="small"
      />
    </a-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from "vue";
import dayjs from "dayjs";
import { UserOutlined, BookOutlined, TeamOutlined, FileTextOutlined } from "@ant-design/icons-vue";
import { statisticsApi } from "../api/statistics";
import type { DashboardData, CourseBookingStat } from "../api/statistics";

const dashboard = ref<DashboardData | null>(null);
const courseStats = ref<CourseBookingStat[]>([]);
const dateRange = ref<[dayjs.Dayjs, dayjs.Dayjs]>([dayjs().subtract(7, "day"), dayjs()]);

const statCards = computed(() => [
  { title: "会员总数", value: dashboard.value?.totalMembers ?? 0, icon: UserOutlined, color: "#1677ff" },
  { title: "课程总数", value: dashboard.value?.totalCourses ?? 0, icon: BookOutlined, color: "#52c41a" },
  { title: "教练总数", value: dashboard.value?.totalCoaches ?? 0, icon: TeamOutlined, color: "#faad14" },
  { title: "今日预约", value: dashboard.value?.todayBookings ?? 0, icon: FileTextOutlined, color: "#ff4d4f" },
]);

const columns = [
  { title: "日期", dataIndex: "date", key: "date", width: 110 },
  { title: "课程", dataIndex: "courseName", key: "courseName" },
  { title: "教练", dataIndex: "coachName", key: "coachName" },
  { title: "已预约", dataIndex: "booked", key: "booked", width: 80 },
  { title: "容量", dataIndex: "capacity", key: "capacity", width: 80 },
  {
    title: "上座率",
    dataIndex: "occupancyRate",
    key: "occupancyRate",
    width: 100,
    customRender: ({ text }: { text: number }) => text + "%",
  },
];

onMounted(() => {
  statisticsApi.dashboard().then((res) => (dashboard.value = res.data));
  loadCourseStats();
});

function loadCourseStats() {
  if (dateRange.value) {
    statisticsApi
      .courseBookings({
        start: dateRange.value[0].format("YYYY-MM-DD"),
        end: dateRange.value[1].format("YYYY-MM-DD"),
      })
      .then((res) => (courseStats.value = res.data));
  }
}

function onDateChange(dates: any) {
  if (dates && dates[0] && dates[1]) {
    dateRange.value = [dates[0], dates[1]];
    loadCourseStats();
  }
}
</script>
