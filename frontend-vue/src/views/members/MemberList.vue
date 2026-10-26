<template>
  <a-card title="会员管理">
    <template #extra>
      <a-input-search
        v-model:value="keyword"
        placeholder="搜索姓名/手机号"
        style="width: 220px"
        @search="onSearch"
      />
    </template>
    <a-table
      rowKey="id"
      :columns="columns"
      :dataSource="data"
      :loading="loading"
      :pagination="{
        current: page,
        total,
        pageSize: 20,
        onChange: (p: number) => { page = p; fetchData(); },
        showTotal: (t: number) => '共 ' + t + ' 条',
      }"
    >
      <template #bodyCell="{ column, record }">
        <template v-if="column.dataIndex === 'gender'">
          {{ record.gender === 1 ? "男" : record.gender === 2 ? "女" : "-" }}
        </template>
        <template v-else-if="column.dataIndex === 'status'">
          <a-tag :color="record.status === 0 ? 'green' : 'red'">
            {{ record.status === 0 ? "正常" : "冻结" }}
          </a-tag>
        </template>
        <template v-else-if="column.key === 'action'">
          <a-button type="link" @click="goDetail(record.id)">详情</a-button>
        </template>
      </template>
    </a-table>
  </a-card>
</template>

<script setup lang="ts">
import { ref, onMounted } from "vue";
import { useRouter } from "vue-router";
import { memberApi } from "../../api/members";
import type { MemberInfo } from "../../api/members";

const router = useRouter();
const data = ref<MemberInfo[]>([]);
const total = ref(0);
const page = ref(1);
const keyword = ref("");
const loading = ref(false);

const columns = [
  { title: "ID", dataIndex: "id", key: "id", width: 60 },
  { title: "姓名", dataIndex: "name", key: "name" },
  { title: "手机号", dataIndex: "phone", key: "phone" },
  { title: "性别", dataIndex: "gender", key: "gender", width: 60 },
  { title: "生日", dataIndex: "birthday", key: "birthday" },
  { title: "状态", dataIndex: "status", key: "status", width: 80 },
  { title: "操作", key: "action", width: 120 },
];

function goDetail(id: number) {
  router.push("/members/" + id);
}

function onSearch() {
  page.value = 1;
  fetchData();
}

async function fetchData() {
  loading.value = true;
  try {
    const res = await memberApi.list({ page: page.value, size: 20, keyword: keyword.value || undefined });
    data.value = res.data.records;
    total.value = res.data.total;
  } finally {
    loading.value = false;
  }
}

onMounted(fetchData);
</script>
