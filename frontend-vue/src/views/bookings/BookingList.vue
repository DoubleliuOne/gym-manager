<template>
  <a-card title="预订管理">
    <template #extra>
      <a-space>
        <a-button @click="showCheckins">签到记录</a-button>
        <a-button type="primary" @click="openBook">
          <template #icon><plus-outlined /></template>新增预订
        </a-button>
      </a-space>
    </template>
    <a-table rowKey="id" :columns="columns" :dataSource="data" :loading="loading" :pagination="{ pageSize: 20 }">
      <template #bodyCell="{ column, record }">
        <template v-if="column.dataIndex === 'status'">
          <a-tag :color="statusColor(record.status)">{{ statusLabel(record.status) }}</a-tag>
        </template>
        <template v-else-if="column.key === 'action'">
          <a-space v-if="record.status === 0">
            <a-button type="link" @click="openCheckin(record)">签到</a-button>
            <a-popconfirm title="确定取消预订吗？" @confirm="handleCancel(record)">
              <a-button type="link" danger>取消</a-button>
            </a-popconfirm>
          </a-space>
        </template>
      </template>
    </a-table>

    <a-modal v-model:open="bookOpen" title="新增预订" @ok="handleBook" destroyOnClose>
      <a-form ref="bookFormRef" :model="bookForm" layout="vertical">
        <a-form-item name="memberId" label="会员" :rules="[{ required: true }]">
          <a-select v-model:value="bookForm.memberId" showSearch
            :filterOption="(input: string, opt: any) => (opt.label || '').includes(input)"
            :options="memberOptions" />
        </a-form-item>
        <a-form-item name="scheduleId" label="排课" :rules="[{ required: true }]">
          <a-select v-model:value="bookForm.scheduleId" showSearch
            :filterOption="(input: string, opt: any) => (opt.label || '').includes(input)"
            :options="scheduleOptions" />
        </a-form-item>
      </a-form>
    </a-modal>

    <a-modal v-model:open="checkinOpen" title="签到" @ok="handleCheckin" destroyOnClose>
      <a-form ref="checkinFormRef" :model="checkinForm" layout="vertical">
        <a-form-item name="bookingId" label="预订ID" :rules="[{ required: true }]">
          <a-select v-model:value="checkinForm.bookingId" showSearch :options="bookingOptions" />
        </a-form-item>
        <a-form-item name="method" label="签到方式" :rules="[{ required: true }]">
          <a-select v-model:value="checkinForm.method" :options="[
            { value: 0, label: '扫码' }, { value: 1, label: '手动' }, { value: 2, label: '自动' },
          ]" />
        </a-form-item>
      </a-form>
    </a-modal>

    <a-modal v-model:open="checkinRecordsOpen" title="签到记录" :footer="null" width="700px" destroyOnClose>
      <a-table rowKey="id" :columns="checkinColumns" :dataSource="checkinRecords" :pagination="false" size="small" />
    </a-modal>
  </a-card>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, computed } from "vue";
import { message } from "ant-design-vue";
import { PlusOutlined } from "@ant-design/icons-vue";
import { bookingApi } from "../../api/bookings";
import { memberApi } from "../../api/members";
import { scheduleApi } from "../../api/schedules";
import type { Booking, CheckInRecord } from "../../api/bookings";
import type { MemberInfo } from "../../api/members";
import type { CourseSchedule } from "../../api/schedules";

const data = ref<Booking[]>([]);
const loading = ref(false);
const bookOpen = ref(false);
const checkinOpen = ref(false);
const checkinRecordsOpen = ref(false);
const checkinRecords = ref<CheckInRecord[]>([]);
const memberOptions = ref<{ value: number; label: string }[]>([]);
const scheduleOptions = ref<{ value: number; label: string }[]>([]);
const bookingOptions = computed(() =>
  data.value.filter((b) => b.status === 0).map((b) => ({
    value: b.id,
    label: "#" + b.id + " 会员" + b.memberId + " 排课" + b.scheduleId,
  }))
);
const bookForm = reactive({ memberId: undefined as number | undefined, scheduleId: undefined as number | undefined });
const checkinForm = reactive({ bookingId: undefined as number | undefined, method: 1 });

const statusMap: Record<number, [string, string]> = { 0: ["已预订", "blue"], 1: ["已签到", "green"], 2: ["已取消", "red"] };
function statusColor(s: number) { return (statusMap[s] || ["未知", "default"])[1]; }
function statusLabel(s: number) { return (statusMap[s] || ["未知", "default"])[0]; }

const columns = [
  { title: "ID", dataIndex: "id", key: "id", width: 60 },
  { title: "会员ID", dataIndex: "memberId", key: "memberId", width: 80 },
  { title: "排课ID", dataIndex: "scheduleId", key: "scheduleId", width: 80 },
  { title: "状态", dataIndex: "status", key: "status", width: 80 },
  { title: "创建时间", dataIndex: "createdAt", key: "createdAt" },
  { title: "操作", key: "action", width: 180 },
];

const checkinColumns = [
  { title: "ID", dataIndex: "id", width: 60 },
  { title: "预订ID", dataIndex: "bookingId", width: 80 },
  { title: "会员ID", dataIndex: "memberId", width: 80 },
  { title: "方式", dataIndex: "method", width: 80,
    customRender: ({ text }: { text: number }) => ({ 0: "扫码", 1: "手动", 2: "自动" }[text] || "未知") },
  { title: "签到时间", dataIndex: "checkinTime" },
];

async function fetchData() {
  loading.value = true;
  try {
    const res = await bookingApi.list();
    data.value = res.data;
  } finally {
    loading.value = false;
  }
}

async function fetchOptions() {
  const [mRes, sRes] = await Promise.all([
    memberApi.list({ page: 1, size: 200 }),
    scheduleApi.list(),
  ]);
  memberOptions.value = mRes.data.records.map((m: MemberInfo) => ({
    value: m.id, label: m.name + "(" + m.phone + ")"
  }));
  scheduleOptions.value = sRes.data.filter((s: CourseSchedule) => s.status === 0).map((s: CourseSchedule) => ({
    value: s.id,
    label: "#" + s.id + " " + s.classDate + " " + s.startTime + "-" + s.endTime + " (" + s.bookedCount + "/" + s.actualCapacity + ")",
  }));
}

async function handleBook() {
  try {
    await bookingApi.create(bookForm as any);
    message.success("预订成功");
    bookOpen.value = false;
    fetchData();
  } catch (e: any) {
    message.error(e.message || "预订失败");
  }
}

async function handleCancel(record: Booking) {
  try {
    await bookingApi.cancel(record.id, { memberId: record.memberId });
    message.success("已取消");
    fetchData();
  } catch (e: any) {
    message.error(e.message || "取消失败");
  }
}

function openCheckin(record: Booking) {
  checkinForm.bookingId = record.id;
  checkinForm.method = 1;
  checkinOpen.value = true;
}

async function handleCheckin() {
  try {
    await bookingApi.checkin(checkinForm as any);
    message.success("签到成功");
    checkinOpen.value = false;
    fetchData();
  } catch (e: any) {
    message.error(e.message || "签到失败");
  }
}

async function showCheckins() {
  try {
    const res = await bookingApi.checkins();
    checkinRecords.value = res.data;
    checkinRecordsOpen.value = true;
  } catch (e: any) {
    message.error(e.message || "加载失败");
  }
}

function openBook() {
  bookForm.memberId = undefined;
  bookForm.scheduleId = undefined;
  bookOpen.value = true;
}

onMounted(() => { fetchData(); fetchOptions(); });
</script>
