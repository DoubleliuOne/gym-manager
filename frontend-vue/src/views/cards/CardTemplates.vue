<template>
  <a-card title="卡模板管理">
    <template #extra>
      <a-button type="primary" @click="openEdit()">
        <template #icon><plus-outlined /></template>新增模板
      </a-button>
    </template>
    <a-table rowKey="id" :columns="columns" :dataSource="data" :loading="loading" :pagination="false">
      <template #bodyCell="{ column, record }">
        <template v-if="column.dataIndex === 'type'">
          <a-tag :color="record.type === 0 ? 'blue' : 'orange'">
            {{ record.type === 0 ? "时限卡" : "次卡" }}
          </a-tag>
        </template>
        <template v-else-if="column.dataIndex === 'price'">
          ¥{{ record.price.toFixed(2) }}
        </template>
        <template v-else-if="column.dataIndex === 'status'">
          <a-tag :color="record.status === 0 ? 'green' : 'red'">
            {{ record.status === 0 ? "启用" : "停用" }}
          </a-tag>
        </template>
        <template v-else-if="column.key === 'action'">
          <a-button type="link" @click="openEdit(record)">编辑</a-button>
        </template>
      </template>
    </a-table>

    <a-modal
      v-model:open="modalOpen"
      :title="editRecord ? '编辑模板' : '新增模板'"
      @ok="handleSave"
      destroyOnClose
    >
      <a-form ref="formRef" :model="form" layout="vertical">
        <a-form-item name="name" label="名称" :rules="[{ required: true }]">
          <a-input v-model:value="form.name" />
        </a-form-item>
        <a-form-item name="type" label="类型" :rules="[{ required: true }]">
          <a-select v-model:value="form.type" :options="[{ value: 0, label: '时限卡' }, { value: 1, label: '次卡' }]" />
        </a-form-item>
        <a-form-item name="durationDays" label="有效天数" :rules="[{ required: true }]">
          <a-input-number v-model:value="form.durationDays" :min="1" style="width: 100%" />
        </a-form-item>
        <a-form-item name="totalCount" label="总次数（次卡专用）">
          <a-input-number v-model:value="form.totalCount" :min="0" style="width: 100%" />
        </a-form-item>
        <a-form-item name="price" label="价格" :rules="[{ required: true }]">
          <a-input-number v-model:value="form.price" :min="0" :precision="2" prefix="¥" style="width: 100%" />
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
import { cardTemplateApi } from "../../api/cardTemplates";
import type { CardTemplate } from "../../api/cardTemplates";

const data = ref<CardTemplate[]>([]);
const loading = ref(false);
const modalOpen = ref(false);
const editRecord = ref<CardTemplate | null>(null);
const form = reactive({ name: "", type: 0, durationDays: 30, totalCount: 0, price: 0, status: 0 });

const columns = [
  { title: "ID", dataIndex: "id", key: "id", width: 60 },
  { title: "名称", dataIndex: "name", key: "name" },
  { title: "类型", dataIndex: "type", key: "type", width: 80 },
  { title: "有效天数", dataIndex: "durationDays", key: "durationDays", width: 90 },
  { title: "总次数", dataIndex: "totalCount", key: "totalCount", width: 80 },
  { title: "价格", dataIndex: "price", key: "price", width: 100 },
  { title: "状态", dataIndex: "status", key: "status", width: 80 },
  { title: "操作", key: "action", width: 100 },
];

async function fetchData() {
  loading.value = true;
  try {
    const res = await cardTemplateApi.list();
    data.value = res.data;
  } finally {
    loading.value = false;
  }
}

function openEdit(record?: CardTemplate) {
  editRecord.value = record || null;
  if (record) {
    Object.assign(form, record);
  } else {
    Object.assign(form, { name: "", type: 0, durationDays: 30, totalCount: 0, price: 0, status: 0 });
  }
  modalOpen.value = true;
}

async function handleSave() {
  try {
    if (editRecord.value) {
      await cardTemplateApi.update(editRecord.value.id, form);
      message.success("更新成功");
    } else {
      await cardTemplateApi.create(form);
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
