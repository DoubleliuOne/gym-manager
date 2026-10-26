<template>
  <a-card title="课程管理">
    <template #extra>
      <a-button type="primary" @click="openEdit()">
        <template #icon><plus-outlined /></template>新增课程
      </a-button>
    </template>
    <a-table rowKey="id" :columns="columns" :dataSource="data" :loading="loading" :pagination="false">
      <template #bodyCell="{ column, record }">
        <template v-if="column.dataIndex === 'status'">
          <a-tag :color="record.status === 0 ? 'green' : 'red'">
            {{ record.status === 0 ? "启用" : "停用" }}
          </a-tag>
        </template>
        <template v-else-if="column.key === 'action'">
          <a-button type="link" @click="openEdit(record)">编辑</a-button>
        </template>
      </template>
    </a-table>

    <a-modal v-model:open="modalOpen" :title="editRecord ? '编辑课程' : '新增课程'"
      @ok="handleSave" destroyOnClose>
      <a-form ref="formRef" :model="form" layout="vertical">
        <a-form-item name="name" label="课程名称" :rules="[{ required: true }]">
          <a-input v-model:value="form.name" />
        </a-form-item>
        <a-form-item name="description" label="描述">
          <a-textarea v-model:value="form.description" :rows="3" />
        </a-form-item>
        <a-form-item name="maxCapacity" label="最大容量" :rules="[{ required: true }]">
          <a-input-number v-model:value="form.maxCapacity" :min="1" style="width: 100%" />
        </a-form-item>
        <a-form-item name="durationMinutes" label="时长(分钟)" :rules="[{ required: true }]">
          <a-input-number v-model:value="form.durationMinutes" :min="1" style="width: 100%" />
        </a-form-item>
        <a-form-item name="status" label="状态">
          <a-select v-model:value="form.status" :options="[{ value: 0, label: '启用' }, { value: 1, label: '停用' }]" />
        </a-form-item>
      </a-form>
    </a-modal>
  </a-card>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from "vue";
import { message } from "ant-design-vue";
import { PlusOutlined } from "@ant-design/icons-vue";
import { courseApi } from "../../api/courses";
import type { Course } from "../../api/courses";

const data = ref<Course[]>([]);
const loading = ref(false);
const modalOpen = ref(false);
const editRecord = ref<Course | null>(null);
const form = reactive({ name: "", description: "", maxCapacity: 20, durationMinutes: 60, status: 0 });

const columns = [
  { title: "ID", dataIndex: "id", key: "id", width: 60 },
  { title: "名称", dataIndex: "name", key: "name" },
  { title: "描述", dataIndex: "description", key: "description", ellipsis: true },
  { title: "最大容量", dataIndex: "maxCapacity", key: "maxCapacity", width: 90 },
  { title: "时长(分钟)", dataIndex: "durationMinutes", key: "durationMinutes", width: 100 },
  { title: "状态", dataIndex: "status", key: "status", width: 80 },
  { title: "操作", key: "action", width: 100 },
];

async function fetchData() {
  loading.value = true;
  try {
    const res = await courseApi.list();
    data.value = res.data;
  } finally {
    loading.value = false;
  }
}

function openEdit(record?: Course) {
  editRecord.value = record || null;
  if (record) Object.assign(form, record);
  else Object.assign(form, { name: "", description: "", maxCapacity: 20, durationMinutes: 60, status: 0 });
  modalOpen.value = true;
}

async function handleSave() {
  try {
    if (editRecord.value) {
      await courseApi.update(editRecord.value.id, form);
      message.success("更新成功");
    } else {
      await courseApi.create(form);
      message.success("创建成功");
    }
    modalOpen.value = false;
    editRecord.value = null;
    fetchData();
  } catch (e: any) {
    message.error(e.message || "操作失败");
  }
}

onMounted(fetchData);
</script>
