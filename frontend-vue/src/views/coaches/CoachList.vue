<template>
  <a-card title="教练管理">
    <template #extra>
      <a-button type="primary" @click="openEdit()">
        <template #icon><plus-outlined /></template>新增教练
      </a-button>
    </template>
    <a-table rowKey="id" :columns="columns" :dataSource="data" :loading="loading" :pagination="false">
      <template #bodyCell="{ column, record }">
        <template v-if="column.dataIndex === 'status'">
          <a-tag :color="record.status === 0 ? 'green' : 'red'">
            {{ record.status === 0 ? "在职" : "离职" }}
          </a-tag>
        </template>
        <template v-else-if="column.key === 'action'">
          <a-space>
            <a-button type="link" @click="openEdit(record)">编辑</a-button>
            <a-popconfirm title="确定删除吗？若有关联排课将无法删除。" @confirm="handleDelete(record)">
              <a-button type="link" danger>删除</a-button>
            </a-popconfirm>
          </a-space>
        </template>
      </template>
    </a-table>

    <a-modal v-model:open="modalOpen" :title="editRecord ? '编辑教练' : '新增教练'"
      @ok="handleSave" destroyOnClose>
      <a-form ref="formRef" :model="form" layout="vertical">
        <a-form-item name="name" label="姓名" :rules="[{ required: true }]">
          <a-input v-model:value="form.name" />
        </a-form-item>
        <a-form-item name="phone" label="手机号" :rules="[{ required: true }]">
          <a-input v-model:value="form.phone" />
        </a-form-item>
        <a-form-item name="specialty" label="专长">
          <a-input v-model:value="form.specialty" placeholder="如：瑜伽、普拉提" />
        </a-form-item>
        <a-form-item name="status" label="状态">
          <a-select v-model:value="form.status" :options="[{ value: 0, label: '在职' }, { value: 1, label: '离职' }]" />
        </a-form-item>
      </a-form>
    </a-modal>
  </a-card>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from "vue";
import { message } from "ant-design-vue";
import { PlusOutlined } from "@ant-design/icons-vue";
import { coachApi } from "../../api/coaches";
import type { Coach } from "../../api/coaches";

const data = ref<Coach[]>([]);
const loading = ref(false);
const modalOpen = ref(false);
const editRecord = ref<Coach | null>(null);
const form = reactive({ name: "", phone: "", specialty: "", status: 0 });

const columns = [
  { title: "ID", dataIndex: "id", key: "id", width: 60 },
  { title: "姓名", dataIndex: "name", key: "name" },
  { title: "手机号", dataIndex: "phone", key: "phone" },
  { title: "专长", dataIndex: "specialty", key: "specialty" },
  { title: "状态", dataIndex: "status", key: "status", width: 80 },
  { title: "创建时间", dataIndex: "createdAt", key: "createdAt" },
  { title: "操作", key: "action", width: 140 },
];

async function fetchData() {
  loading.value = true;
  try {
    const res = await coachApi.list();
    data.value = res.data;
  } finally {
    loading.value = false;
  }
}

function openEdit(record?: Coach) {
  editRecord.value = record || null;
  if (record) {
    Object.assign(form, record);
  } else {
    Object.assign(form, { name: "", phone: "", specialty: "", status: 0 });
  }
  modalOpen.value = true;
}

async function handleSave() {
  try {
    if (editRecord.value) {
      await coachApi.update(editRecord.value.id, form);
      message.success("更新成功");
    } else {
      await coachApi.create(form);
      message.success("创建成功");
    }
    modalOpen.value = false;
    editRecord.value = null;
    fetchData();
  } catch (e: any) {
    message.error(e.message || "操作失败");
  }
}

async function handleDelete(record: Coach) {
  try {
    await coachApi.delete(record.id);
    message.success("删除成功");
    fetchData();
  } catch (e: any) {
    message.error(e.message || "删除失败，请先删除关联排课");
  }
}

onMounted(fetchData);
</script>
