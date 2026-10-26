<template>
  <a-card title="排课管理">
    <template #extra>
      <a-space>
        <a-date-picker placeholder="筛选日期" allowClear @change="onDateFilter" />
        <a-button type="primary" @click="openEdit()">
          <template #icon><plus-outlined /></template>新增排课
        </a-button>
      </a-space>
    </template>
    <a-table rowKey="id" :columns="columns" :dataSource="data" :loading="loading" :pagination="{ pageSize: 20 }">
      <template #bodyCell="{ column, record }">
        <template v-if="column.dataIndex === 'courseId'">{{ courseNameMap[record.courseId] || record.courseId }}</template>
        <template v-else-if="column.dataIndex === 'coachId'">{{ coachNameMap[record.coachId] || record.coachId }}</template>
        <template v-else-if="column.dataIndex === 'status'">
          <a-tag :color="record.status === 0 ? 'green' : 'red'">
            {{ record.status === 0 ? "正常" : "已取消" }}
          </a-tag>
        </template>
        <template v-else-if="column.key === 'action'">
          <a-space>
            <a-button type="link" @click="openEdit(record)">编辑</a-button>
            <a-popconfirm v-if="record.status === 0" title="确定取消排课吗？" @confirm="handleCancel(record)">
              <a-button type="link" danger>取消</a-button>
            </a-popconfirm>
          </a-space>
        </template>
      </template>
    </a-table>

    <a-modal v-model:open="modalOpen" :title="editRecord ? '编辑排课' : '新增排课'"
      @ok="handleSave" destroyOnClose :width="560">
      <a-form ref="formRef" :model="form" layout="vertical">
        <a-form-item name="courseId" label="课程" :rules="[{ required: true }]">
          <a-select v-model:value="form.courseId" showSearch
            :filterOption="(input: string, opt: any) => (opt.label || '').includes(input)"
            :options="courseOptions" />
        </a-form-item>
        <a-form-item name="coachId" label="教练" :rules="[{ required: true }]">
          <a-select v-model:value="form.coachId" showSearch
            :filterOption="(input: string, opt: any) => (opt.label || '').includes(input)"
            :options="coachOptions" />
        </a-form-item>
        <a-space size="middle">
          <a-form-item name="classDate" label="上课日期" :rules="[{ required: true }]">
            <a-date-picker v-model:value="form.classDate" />
          </a-form-item>
          <a-form-item name="startTime" label="开始时间" :rules="[{ required: true }]">
            <a-time-picker v-model:value="form.startTime" format="HH:mm" />
          </a-form-item>
          <a-form-item name="endTime" label="结束时间" :rules="[{ required: true }]">
            <a-time-picker v-model:value="form.endTime" format="HH:mm" />
          </a-form-item>
        </a-space>
        <a-space size="middle">
          <a-form-item name="actualCapacity" label="容量" :rules="[{ required: true }]">
            <a-input-number v-model:value="form.actualCapacity" :min="1" />
          </a-form-item>
          <a-form-item name="bookedCount" label="已预约">
            <a-input-number v-model:value="form.bookedCount" :min="0" />
          </a-form-item>
        </a-space>
        <a-form-item name="status" label="状态">
          <a-select v-model:value="form.status" :options="[{ value: 0, label: '正常' }, { value: 1, label: '取消' }]" />
        </a-form-item>
      </a-form>
    </a-modal>
  </a-card>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from "vue";
import { message } from "ant-design-vue";
import { PlusOutlined } from "@ant-design/icons-vue";
import dayjs from "dayjs";
import { scheduleApi } from "../../api/schedules";
import { courseApi } from "../../api/courses";
import { coachApi } from "../../api/coaches";
import type { CourseSchedule } from "../../api/schedules";
import type { Course } from "../../api/courses";
import type { Coach } from "../../api/coaches";

const data = ref<CourseSchedule[]>([]);
const loading = ref(false);
const modalOpen = ref(false);
const editRecord = ref<CourseSchedule | null>(null);
const filterDate = ref<string>("");
const courseNameMap = ref<Record<number, string>>({});
const coachNameMap = ref<Record<number, string>>({});
const courseOptions = ref<{ value: number; label: string }[]>([]);
const coachOptions = ref<{ value: number; label: string }[]>([]);
const form = reactive({
  courseId: undefined as number | undefined,
  coachId: undefined as number | undefined,
  classDate: undefined as any,
  startTime: undefined as any,
  endTime: undefined as any,
  actualCapacity: 20,
  bookedCount: 0,
  status: 0,
});

const columns = [
  { title: "ID", dataIndex: "id", key: "id", width: 60 },
  { title: "课程", dataIndex: "courseId", key: "courseId" },
  { title: "教练", dataIndex: "coachId", key: "coachId" },
  { title: "日期", dataIndex: "classDate", key: "classDate" },
  { title: "开始", dataIndex: "startTime", key: "startTime" },
  { title: "结束", dataIndex: "endTime", key: "endTime" },
  { title: "容量", dataIndex: "actualCapacity", key: "actualCapacity", width: 70 },
  { title: "已预约", dataIndex: "bookedCount", key: "bookedCount", width: 70 },
  { title: "状态", dataIndex: "status", key: "status", width: 80 },
  { title: "操作", key: "action", width: 150 },
];

async function fetchData() {
  loading.value = true;
  try {
    const res = await scheduleApi.list({ date: filterDate.value || undefined });
    data.value = res.data;
  } finally {
    loading.value = false;
  }
}

async function fetchOptions() {
  const [cRes, coRes] = await Promise.all([courseApi.list(), coachApi.list()]);
  courseOptions.value = cRes.data.map((c: Course) => ({ value: c.id, label: c.name }));
  coachOptions.value = coRes.data.map((c: Coach) => ({ value: c.id, label: c.name }));
  cRes.data.forEach((c: Course) => { courseNameMap.value[c.id] = c.name; });
  coRes.data.forEach((c: Coach) => { coachNameMap.value[c.id] = c.name; });
}

function openEdit(record?: CourseSchedule) {
  editRecord.value = record || null;
  if (record) {
    form.courseId = record.courseId;
    form.coachId = record.coachId;
    form.classDate = dayjs(record.classDate);
    form.startTime = dayjs(record.startTime, "HH:mm:ss");
    form.endTime = dayjs(record.endTime, "HH:mm:ss");
    form.actualCapacity = record.actualCapacity;
    form.bookedCount = record.bookedCount;
    form.status = record.status;
  } else {
    Object.assign(form, { courseId: undefined, coachId: undefined, classDate: undefined, startTime: undefined, endTime: undefined, actualCapacity: 20, bookedCount: 0, status: 0 });
  }
  modalOpen.value = true;
}

async function handleSave() {
  try {
    const payload = {
      courseId: form.courseId,
      coachId: form.coachId,
      classDate: form.classDate?.format("YYYY-MM-DD"),
      startTime: form.startTime?.format("HH:mm:ss"),
      endTime: form.endTime?.format("HH:mm:ss"),
      actualCapacity: form.actualCapacity,
      bookedCount: form.bookedCount,
      status: form.status,
    };
    if (editRecord.value) {
      await scheduleApi.update(editRecord.value.id, payload);
      message.success("更新成功");
    } else {
      await scheduleApi.create(payload);
      message.success("创建成功");
    }
    modalOpen.value = false;
    editRecord.value = null;
    fetchData();
  } catch (e: any) {
    message.error(e.message || "操作失败");
  }
}

async function handleCancel(record: CourseSchedule) {
  try {
    await scheduleApi.cancel(record.id);
    message.success("已取消");
    fetchData();
  } catch (e: any) {
    message.error(e.message || "取消失败");
  }
}

function onDateFilter(date: any) {
  filterDate.value = date ? date.format("YYYY-MM-DD") : "";
  fetchData();
}

onMounted(() => { fetchData(); fetchOptions(); });
</script>
